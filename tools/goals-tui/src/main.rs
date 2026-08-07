use ansi_to_tui::IntoText as _;
use crossterm::{
    event::{
        self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind, MouseButton,
        MouseEventKind,
    },
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use ratatui::{
    Frame, Terminal,
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Wrap},
};
use regex::Regex;
use serde_json::Value;
use std::{
    collections::{BTreeSet, HashMap, HashSet},
    env,
    error::Error,
    fs,
    io::{self, stdout},
    path::{Path, PathBuf},
    process::Command,
    time::{Duration, Instant, UNIX_EPOCH},
};

const REPEAT_DELAY: Duration = Duration::from_millis(160);

#[derive(Clone)]
struct Task {
    id: String,
    title: String,
    status: String,
    priority: String,
    blocked_by: Vec<String>,
    references: Vec<String>,
    targets: Vec<String>,
    skills: Vec<String>,
    commands: Vec<String>,
}

#[derive(Clone)]
struct Goal {
    id: u32,
    status: String,
    slug: String,
    path: PathBuf,
    artifacts: Vec<String>,
    tasks: Vec<Task>,
    dependencies: Vec<u32>,
    architecture: Vec<String>,
    deliverables: Vec<String>,
    linked_maps: Vec<String>,
    mentioned_maps: Vec<String>,
    completed_at: u64,
}

#[derive(Clone)]
struct Ticket {
    id: String,
    title: String,
    status: String,
    path: PathBuf,
}

#[derive(Clone)]
struct Map {
    name: String,
    status: String,
    path: PathBuf,
    tickets: Vec<Ticket>,
    linked_goals: Vec<usize>,
    mentioned_goals: Vec<usize>,
}

#[derive(Clone)]
enum Entry {
    Section(String, String),
    Goal(usize),
    Resources(usize),
    Task(usize, usize),
    Map(usize),
    Relationship(usize, String),
    Ticket(usize, usize),
    File(PathBuf, String),
}

struct App {
    root: PathBuf,
    goals: Vec<Goal>,
    maps: Vec<Map>,
    tab: usize,
    entries: Vec<Entry>,
    selected: usize,
    collapsed: HashSet<String>,
    list_area: Rect,
    header_area: Rect,
    preview_area: Rect,
    list_offset: usize,
    preview_offset: u16,
    last_key: Option<KeyCode>,
    last_key_at: Option<Instant>,
}

fn read(path: &Path) -> String {
    fs::read_to_string(path).unwrap_or_default()
}
fn exists(path: &Path) -> bool {
    path.exists()
}

fn readable_source(path: &Path) -> bool {
    path.extension().and_then(|extension| extension.to_str()) == Some("md")
        || path.file_name().and_then(|name| name.to_str()) == Some("tasks.jsonl")
}

fn modified_at(path: &Path) -> u64 {
    fs::metadata(path)
        .and_then(|metadata| metadata.modified())
        .ok()
        .and_then(|time| time.duration_since(UNIX_EPOCH).ok())
        .map(|duration| duration.as_secs())
        .unwrap_or_default()
}

fn collect_goal_sources(directory: &Path, files: &mut BTreeSet<PathBuf>) {
    let Ok(entries) = fs::read_dir(directory) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_goal_sources(&path, files);
        } else if readable_source(&path) {
            files.insert(path);
        }
    }
}

fn preview_file(path: &Path, width: u16) -> Text<'static> {
    if path.extension().and_then(|extension| extension.to_str()) != Some("md") {
        let output = Command::new("bat")
            .args(["--color=always", "--style=plain", "--paging=never"])
            .arg(path)
            .output();
        return match output {
            Ok(output) if output.status.success() => output
                .stdout
                .into_text()
                .unwrap_or_else(|_| Text::from(read(path))),
            _ => Text::from(read(path)),
        };
    }
    let output = Command::new("glow")
        .env("CLICOLOR_FORCE", "1")
        .env("FORCE_COLOR", "1")
        .arg("--width")
        .arg(width.max(20).to_string())
        .args(["--style", "dark"])
        .arg(path)
        .output();
    match output {
        Ok(output) if output.status.success() => output
            .stdout
            .into_text()
            .unwrap_or_else(|_| Text::from(read(path))),
        _ => Text::from(read(path)),
    }
}

fn run_inline(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    mut command: Command,
) -> Result<(), Box<dyn Error>> {
    disable_raw_mode()?;
    execute!(stdout(), LeaveAlternateScreen)?;
    let _ = command.status();
    execute!(stdout(), EnterAlternateScreen, EnableMouseCapture)?;
    enable_raw_mode()?;
    terminal.draw(|frame| frame.render_widget(Clear, frame.area()))?;
    while event::poll(Duration::ZERO)? {
        event::read()?;
    }
    Ok(())
}

fn open_in_editor(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    path: &Path,
) -> Result<(), Box<dyn Error>> {
    let mut command = Command::new("nvim");
    command.arg("-R").arg(path);
    run_inline(terminal, command)
}

fn frontmatter(path: &Path) -> HashMap<String, String> {
    let mut result = HashMap::new();
    let text = read(path);
    let mut lines = text.lines();
    if lines.next() != Some("---") {
        return result;
    }
    for line in lines {
        if line == "---" {
            break;
        }
        if let Some((key, value)) = line.split_once(':') {
            result.insert(
                key.trim().to_string(),
                value.trim().trim_matches('"').to_string(),
            );
        }
    }
    result
}

fn string_array(value: &Value, key: &str) -> Vec<String> {
    value
        .get(key)
        .and_then(Value::as_array)
        .map(|items| {
            items
                .iter()
                .filter_map(Value::as_str)
                .map(ToString::to_string)
                .collect()
        })
        .unwrap_or_default()
}

fn parse_tasks(path: &Path) -> Vec<Task> {
    read(path)
        .lines()
        .skip(1)
        .filter_map(|line| serde_json::from_str::<Value>(line).ok())
        .filter_map(|value| {
            Some(Task {
                id: value.get("id")?.as_str()?.to_string(),
                title: value.get("title")?.as_str()?.to_string(),
                status: value
                    .get("status")
                    .and_then(Value::as_str)
                    .unwrap_or("unknown")
                    .to_string(),
                priority: value
                    .get("priority")
                    .map(|v| v.to_string().trim_matches('"').to_string())
                    .unwrap_or_else(|| "-".to_string()),
                blocked_by: string_array(&value, "blocked_by"),
                references: string_array(&value, "references"),
                targets: string_array(&value, "file_targets"),
                skills: string_array(&value, "required_skills"),
                commands: string_array(&value, "verification_commands"),
            })
        })
        .collect()
}

fn parse_prd(path: &Path) -> (Vec<u32>, Vec<String>, Vec<String>) {
    let goal_re = Regex::new(r"(?i)goals?\s+(\d+)").unwrap();
    let architecture_re = Regex::new(r"\]\(([^)]+architecture/[^)]+)\)").unwrap();
    let code_re = Regex::new(r"`([^`]+)`").unwrap();
    let mut dependencies = BTreeSet::new();
    let mut architecture = BTreeSet::new();
    let mut deliverables = BTreeSet::new();
    let mut in_deliverables = false;
    for line in read(path).lines() {
        if line.starts_with("## ") {
            in_deliverables = line.starts_with("## Deliverables");
        }
        if line.starts_with("**Dependencies:**") {
            for capture in goal_re.captures_iter(line) {
                if let Ok(id) = capture[1].parse() {
                    dependencies.insert(id);
                }
            }
            for token in line.split(|c: char| !c.is_ascii_digit()) {
                if let Ok(id) = token.parse() {
                    dependencies.insert(id);
                }
            }
        }
        for capture in architecture_re.captures_iter(line) {
            architecture.insert(capture[1].to_string());
        }
        if in_deliverables {
            for capture in code_re.captures_iter(line) {
                deliverables.insert(capture[1].to_string());
            }
        }
    }
    (
        dependencies.into_iter().collect(),
        architecture.into_iter().collect(),
        deliverables.into_iter().collect(),
    )
}

fn parse_goals(root: &Path) -> Vec<Goal> {
    let planning = root.join("resources/planning");
    let goal_re = Regex::new(r"^goal-(\d+)-(todo|wip|cmp|retired)-(.+)$").unwrap();
    let mut goals = vec![];
    for entry in fs::read_dir(planning).into_iter().flatten().flatten() {
        if !entry.file_type().map(|kind| kind.is_dir()).unwrap_or(false) {
            continue;
        }
        let name = entry.file_name().to_string_lossy().to_string();
        let Some(capture) = goal_re.captures(&name) else {
            continue;
        };
        let path = entry.path();
        let prd = path.join("PRD.md");
        let tasks = path.join("tasks.jsonl");
        let completed_at = modified_at(&path.join("handoff.md"))
            .max(modified_at(&tasks))
            .max(modified_at(&prd));
        let (dependencies, architecture, deliverables) = parse_prd(&prd);
        let mut artifacts = vec![];
        for name in [
            "PRD.md",
            "tasks.jsonl",
            "architecture.d2",
            "architecture.svg",
            "handoff.md",
            "bugs.md",
            "retired.md",
        ] {
            if exists(&path.join(name)) {
                artifacts.push(name.to_string());
            }
        }
        goals.push(Goal {
            id: capture[1].parse().unwrap_or_default(),
            status: capture[2].to_string(),
            slug: capture[3].to_string(),
            path,
            artifacts,
            tasks: if exists(&tasks) {
                parse_tasks(&tasks)
            } else {
                vec![]
            },
            dependencies,
            architecture,
            deliverables,
            linked_maps: vec![],
            mentioned_maps: vec![],
            completed_at,
        });
    }
    goals.sort_by_key(|goal| goal.id);
    goals
}

fn map_goal_evidence(path: &Path) -> (HashSet<u32>, HashSet<u32>) {
    let direct_re = Regex::new(r"goal-(\d+)-(?:todo|wip|cmp|retired)-").unwrap();
    let mention_re = Regex::new(r"(?i)Goal\s+(\d+)").unwrap();
    let mut linked = HashSet::new();
    let mut mentioned = HashSet::new();
    let mut files = vec![path.join("MAP.md"), path.join("HANDOFF.md")];
    if let Ok(entries) = fs::read_dir(path.join("tickets")) {
        files.extend(entries.flatten().map(|entry| entry.path()));
    }
    for file in files {
        for capture in direct_re.captures_iter(&read(&file)) {
            linked.insert(capture[1].parse().unwrap_or_default());
        }
        for capture in mention_re.captures_iter(&read(&file)) {
            mentioned.insert(capture[1].parse().unwrap_or_default());
        }
    }
    for id in &linked {
        mentioned.remove(id);
    }
    (linked, mentioned)
}

fn parse_maps(root: &Path, goals: &mut [Goal]) -> Vec<Map> {
    let maps_root = root.join("resources/planning/wayfinding");
    let mut maps = vec![];
    for entry in fs::read_dir(maps_root).into_iter().flatten().flatten() {
        if !entry.file_type().map(|kind| kind.is_dir()).unwrap_or(false) {
            continue;
        }
        let path = entry.path();
        let metadata = frontmatter(&path.join("MAP.md"));
        let mut tickets = vec![];
        if let Ok(ticket_entries) = fs::read_dir(path.join("tickets")) {
            for ticket in ticket_entries.flatten() {
                let ticket_path = ticket.path();
                if ticket_path.extension().and_then(|value| value.to_str()) != Some("md") {
                    continue;
                }
                let meta = frontmatter(&ticket_path);
                tickets.push(Ticket {
                    id: meta
                        .get("id")
                        .cloned()
                        .unwrap_or_else(|| "ticket".to_string()),
                    title: meta.get("title").cloned().unwrap_or_default(),
                    status: meta
                        .get("status")
                        .cloned()
                        .unwrap_or_else(|| "unknown".to_string()),
                    path: ticket_path,
                });
            }
        }
        tickets.sort_by(|a, b| a.id.cmp(&b.id));
        let (linked, mentioned) = map_goal_evidence(&path);
        let index = maps.len();
        let mut map = Map {
            name: entry.file_name().to_string_lossy().to_string(),
            status: metadata
                .get("status")
                .cloned()
                .unwrap_or_else(|| "unknown".to_string()),
            path,
            tickets,
            linked_goals: vec![],
            mentioned_goals: vec![],
        };
        for (goal_index, goal) in goals.iter_mut().enumerate() {
            if linked.contains(&goal.id) {
                map.linked_goals.push(goal_index);
                goal.linked_maps.push(map.name.clone());
            } else if mentioned.contains(&goal.id) {
                map.mentioned_goals.push(goal_index);
                goal.mentioned_maps.push(map.name.clone());
            }
        }
        let _ = index;
        maps.push(map);
    }
    maps
}

impl App {
    fn new(root: PathBuf) -> Self {
        let mut goals = parse_goals(&root);
        let maps = parse_maps(&root, &mut goals);
        let mut app = Self {
            root,
            goals,
            maps,
            tab: 0,
            entries: vec![],
            selected: 0,
            collapsed: HashSet::new(),
            list_area: Rect::default(),
            header_area: Rect::default(),
            preview_area: Rect::default(),
            list_offset: 0,
            preview_offset: 0,
            last_key: None,
            last_key_at: None,
        };
        for index in 0..app.goals.len() {
            app.collapsed.insert(format!("goal:{index}"));
            app.collapsed.insert(format!("resources:{index}"));
        }
        for (map_index, map) in app.maps.iter().enumerate() {
            for ticket_index in 0..map.tickets.len() {
                app.collapsed
                    .insert(format!("ticket:{map_index}:{ticket_index}"));
            }
        }
        app.rebuild();
        app
    }

    fn resource_files(&self, index: usize) -> Vec<(PathBuf, String)> {
        let goal = &self.goals[index];
        let mut files = BTreeSet::new();
        collect_goal_sources(&goal.path, &mut files);
        for artifact in &goal.artifacts {
            let path = goal.path.join(artifact);
            if readable_source(&path) {
                files.insert(path);
            }
        }
        for task in &goal.tasks {
            for reference in task.references.iter().chain(task.targets.iter()) {
                let path = PathBuf::from(reference);
                let path = if path.is_absolute() {
                    path
                } else {
                    self.root.join(path)
                };
                if readable_source(&path) && exists(&path) {
                    files.insert(path);
                }
            }
        }
        files
            .into_iter()
            .map(|path| {
                let label = path
                    .file_name()
                    .and_then(|name| name.to_str())
                    .unwrap_or("(unnamed)")
                    .to_string();
                (path, format!("      {label}"))
            })
            .collect()
    }

    fn rebuild(&mut self) {
        self.entries.clear();
        self.list_offset = 0;
        self.preview_offset = 0;
        if self.tab == 0 {
            for (status, label) in [
                ("wip", "IN PROGRESS"),
                ("todo", "TO DO"),
                ("cmp", "COMPLETE"),
                ("retired", "RETIRED"),
            ] {
                let mut indices: Vec<_> = self
                    .goals
                    .iter()
                    .enumerate()
                    .filter(|(_, goal)| goal.status == status)
                    .map(|(index, _)| index)
                    .collect();
                if status == "cmp" {
                    indices.sort_by(|left, right| {
                        self.goals[*right]
                            .completed_at
                            .cmp(&self.goals[*left].completed_at)
                            .then_with(|| self.goals[*right].id.cmp(&self.goals[*left].id))
                    });
                }
                if indices.is_empty() {
                    continue;
                }
                let key = format!("group:{status}");
                self.entries.push(Entry::Section(
                    format!("{} ({})", label, indices.len()),
                    key.clone(),
                ));
                if self.collapsed.contains(&key) {
                    continue;
                }
                for index in indices {
                    self.entries.push(Entry::Goal(index));
                    if self.collapsed.contains(&format!("goal:{index}")) {
                        continue;
                    }
                    self.entries.push(Entry::Resources(index));
                    if !self.collapsed.contains(&format!("resources:{index}")) {
                        for (path, label) in self.resource_files(index) {
                            self.entries.push(Entry::File(path, label));
                        }
                    }
                    for (task_index, _) in self.goals[index].tasks.iter().enumerate() {
                        self.entries.push(Entry::Task(index, task_index));
                    }
                }
            }
        } else {
            for (index, map) in self.maps.iter().enumerate() {
                self.entries.push(Entry::Map(index));
                if self.collapsed.contains(&format!("map:{index}")) {
                    continue;
                }
                self.entries
                    .push(Entry::File(map.path.join("MAP.md"), "  MAP".to_string()));
                if exists(&map.path.join("HANDOFF.md")) {
                    self.entries.push(Entry::File(
                        map.path.join("HANDOFF.md"),
                        "  HANDOFF".to_string(),
                    ));
                }
                for (ticket_index, _) in map.tickets.iter().enumerate() {
                    self.entries.push(Entry::Ticket(index, ticket_index));
                    if !self
                        .collapsed
                        .contains(&format!("ticket:{index}:{ticket_index}"))
                    {
                        let ticket = &map.tickets[ticket_index];
                        self.entries.push(Entry::File(
                            ticket.path.clone(),
                            "    Ticket content".to_string(),
                        ));
                    }
                }
                if !map.linked_goals.is_empty() || !map.mentioned_goals.is_empty() {
                    self.entries.push(Entry::Section(
                        "  Goal relationships".to_string(),
                        format!("map-relationships:{index}"),
                    ));
                    if !self
                        .collapsed
                        .contains(&format!("map-relationships:{index}"))
                    {
                        for goal in &map.linked_goals {
                            self.entries
                                .push(Entry::Relationship(*goal, "linked".to_string()));
                        }
                        for goal in &map.mentioned_goals {
                            self.entries
                                .push(Entry::Relationship(*goal, "mentioned".to_string()));
                        }
                    }
                }
            }
        }
        if self.selected >= self.entries.len() {
            self.selected = self.entries.len().saturating_sub(1);
        }
    }

    fn toggle_selected(&mut self) {
        let key = match self.selected_entry() {
            Some(Entry::Section(_, key)) => Some(key.clone()),
            Some(Entry::Goal(index)) => Some(format!("goal:{index}")),
            Some(Entry::Resources(index)) => Some(format!("resources:{index}")),
            Some(Entry::Map(index)) => Some(format!("map:{index}")),
            Some(Entry::Ticket(map, ticket)) => Some(format!("ticket:{map}:{ticket}")),
            _ => None,
        };
        if let Some(key) = key {
            if !self.collapsed.insert(key.clone()) {
                self.collapsed.remove(&key);
            }
            self.rebuild();
        }
    }

    fn selected_entry(&self) -> Option<&Entry> {
        self.entries.get(self.selected)
    }

    fn selected_file(&self) -> Option<PathBuf> {
        match self.selected_entry()? {
            Entry::File(path, _) => Some(path.clone()),
            Entry::Ticket(map, ticket) => Some(self.maps[*map].tickets[*ticket].path.clone()),
            _ => None,
        }
    }

    fn select(&mut self, selected: usize) {
        self.selected = selected.min(self.entries.len().saturating_sub(1));
        self.preview_offset = 0;
        let visible = usize::from(self.list_area.height.saturating_sub(2)).max(1);
        if self.selected < self.list_offset {
            self.list_offset = self.selected;
        } else if self.selected >= self.list_offset + visible {
            self.list_offset = self.selected + 1 - visible;
        }
    }

    fn move_selection(&mut self, delta: isize) {
        if self.entries.is_empty() {
            return;
        }
        let len = self.entries.len();
        let next = (self.selected as isize + delta).rem_euclid(len as isize) as usize;
        self.select(next);
    }

    fn repeat_throttle(&mut self, key: KeyCode) -> bool {
        let now = Instant::now();
        let throttled = self.last_key == Some(key)
            && self
                .last_key_at
                .is_some_and(|at| now.duration_since(at) < REPEAT_DELAY);
        if !throttled {
            self.last_key = Some(key);
            self.last_key_at = Some(now);
        }
        throttled
    }

    fn enter(
        &mut self,
        terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    ) -> Result<(), Box<dyn Error>> {
        if let Some(path) = self.selected_file() {
            return open_in_editor(terminal, &path);
        }
        self.toggle_selected();
        Ok(())
    }

    fn detail(&self) -> String {
        match self.selected_entry() {
            Some(Entry::Goal(index)) => {
                let goal = &self.goals[*index];
                format!(
                    "GOAL {:02}: {}\n\nStatus: {}\nTasks: {}\nPath: {}\n\nWayfinding linked:\n{}\n\nWayfinding mentioned:\n{}",
                    goal.id,
                    goal.slug,
                    goal.status,
                    goal.tasks.len(),
                    goal.path.display(),
                    bullet_list(&goal.linked_maps),
                    bullet_list(&goal.mentioned_maps)
                )
            }
            Some(Entry::Resources(index)) => self.resources(*index),
            Some(Entry::Task(goal_index, task_index)) => {
                let task = &self.goals[*goal_index].tasks[*task_index];
                format!(
                    "TASK {}: {}\n\nStatus: {}    Priority: {}\nBlocked by: {}\n\nReferences:\n{}\n\nImplementation targets:\n{}\n\nRequired skills:\n{}\n\nVerification commands:\n{}",
                    task.id,
                    task.title,
                    task.status,
                    task.priority,
                    task.blocked_by.join(", "),
                    bullet_list(&task.references),
                    bullet_list(&task.targets),
                    bullet_list(&task.skills),
                    bullet_list(&task.commands)
                )
            }
            Some(Entry::Map(index)) => {
                let map = &self.maps[*index];
                format!(
                    "WAYFINDING: {}\n\nStatus: {}\nTickets: {}\n\nDirectly linked goals:\n{}\n\nMentioned goals:\n{}",
                    map.name,
                    map.status,
                    map.tickets.len(),
                    goal_list(&self.goals, &map.linked_goals),
                    goal_list(&self.goals, &map.mentioned_goals)
                )
            }
            Some(Entry::Relationship(index, evidence)) => {
                let goal = &self.goals[*index];
                format!(
                    "{} relationship\n\nGOAL {:02}: {}\nStatus: {}\nTasks: {}\nPath: {}",
                    evidence,
                    goal.id,
                    goal.slug,
                    goal.status,
                    goal.tasks.len(),
                    goal.path.display()
                )
            }
            Some(Entry::Ticket(map_index, ticket_index)) => {
                let ticket = &self.maps[*map_index].tickets[*ticket_index];
                format!(
                    "{}: {}\n\nStatus: {}\n\n{}",
                    ticket.id,
                    ticket.title,
                    ticket.status,
                    read(&ticket.path)
                )
            }
            Some(Entry::File(path, _)) => read(path).to_string(),
            Some(Entry::Section(title, _)) => format!(
                "{}\n\nUse j/k or arrows to select an item.\nUse Tab or 1/2 to switch views.",
                title
            ),
            None => "No planning records found.".to_string(),
        }
    }

    fn detail_text(&self, width: u16) -> Text<'static> {
        match self.selected_entry() {
            Some(Entry::Ticket(map_index, ticket_index)) => {
                let ticket = &self.maps[*map_index].tickets[*ticket_index];
                let mut text = Text::from(format!(
                    "{}: {}\n\nStatus: {}\n\n",
                    ticket.id, ticket.title, ticket.status
                ));
                text.extend(preview_file(&ticket.path, width).lines);
                text
            }
            Some(Entry::File(path, _)) => {
                let mut text = Text::from("");
                text.extend(preview_file(path, width).lines);
                text
            }
            _ => Text::from(self.detail()),
        }
    }

    fn resources(&self, index: usize) -> String {
        let goal = &self.goals[index];
        let mut references = BTreeSet::new();
        let mut targets = BTreeSet::new();
        let mut skills = BTreeSet::new();
        let mut commands = BTreeSet::new();
        for task in &goal.tasks {
            references.extend(task.references.iter().cloned());
            targets.extend(task.targets.iter().cloned());
            skills.extend(task.skills.iter().cloned());
            commands.extend(task.commands.iter().cloned());
        }
        format!(
            "ASSETS & RESOURCES: GOAL {:02}\n\nLifecycle artifacts:\n{}\n\nDependency goals:\n{}\n\nArchitecture inputs:\n{}\n\nPRD deliverables:\n{}\n\nTask references:\n{}\n\nImplementation targets:\n{}\n\nRequired skills:\n{}\n\nVerification commands:\n{}",
            goal.id,
            bullet_list(&goal.artifacts),
            bullet_list(
                &goal
                    .dependencies
                    .iter()
                    .map(|id| format!("Goal {}", id))
                    .collect::<Vec<_>>()
            ),
            bullet_list(&goal.architecture),
            bullet_list(&goal.deliverables),
            bullet_list(&references.into_iter().collect::<Vec<_>>()),
            bullet_list(&targets.into_iter().collect::<Vec<_>>()),
            bullet_list(&skills.into_iter().collect::<Vec<_>>()),
            bullet_list(&commands.into_iter().collect::<Vec<_>>())
        )
    }
}

fn bullet_list(values: &[String]) -> String {
    if values.is_empty() {
        "- None".to_string()
    } else {
        values
            .iter()
            .map(|value| format!("- {}", value))
            .collect::<Vec<_>>()
            .join("\n")
    }
}
fn goal_list(goals: &[Goal], indices: &[usize]) -> String {
    bullet_list(
        &indices
            .iter()
            .map(|index| format!("Goal {:02}: {}", goals[*index].id, goals[*index].slug))
            .collect::<Vec<_>>(),
    )
}
fn status_color(status: &str) -> Color {
    match status {
        "wip" | "in_progress" => Color::Yellow,
        "cmp" | "done" | "resolved" | "decision-complete" => Color::Green,
        "retired" | "out-of-scope" => Color::DarkGray,
        "blocked" => Color::Red,
        _ => Color::Cyan,
    }
}

fn entry_line(app: &App, entry: &Entry) -> (String, Style) {
    match entry {
        Entry::Section(title, key) => (
            format!(
                "{} {}",
                if app.collapsed.contains(key) {
                    "+"
                } else {
                    "-"
                },
                title
            ),
            Style::default()
                .fg(if key == "group:wip" {
                    Color::Yellow
                } else if key == "group:cmp" {
                    Color::Green
                } else if key == "group:retired" {
                    Color::DarkGray
                } else if key == "group:todo" {
                    Color::Cyan
                } else {
                    Color::Blue
                })
                .add_modifier(Modifier::BOLD),
        ),
        Entry::Goal(index) => {
            let goal = &app.goals[*index];
            (
                format!(
                    "  {} G{:02} [{}] {}",
                    if app.collapsed.contains(&format!("goal:{index}")) {
                        "+"
                    } else {
                        "-"
                    },
                    goal.id,
                    goal.status,
                    goal.slug
                ),
                Style::default()
                    .fg(Color::Cyan)
                    .add_modifier(Modifier::BOLD),
            )
        }
        Entry::Resources(index) => (
            format!(
                "    {} Assets & Resources",
                if app.collapsed.contains(&format!("resources:{index}")) {
                    "+"
                } else {
                    "-"
                }
            ),
            Style::default().fg(Color::Magenta),
        ),
        Entry::Task(goal, task) => {
            let task = &app.goals[*goal].tasks[*task];
            (
                format!(
                    "      {} [{}] P{} {}",
                    task.id, task.status, task.priority, task.title
                ),
                Style::default().fg(status_color(&task.status)),
            )
        }
        Entry::Map(index) => {
            let map = &app.maps[*index];
            (
                format!(
                    "{} {} [{}]",
                    if app.collapsed.contains(&format!("map:{index}")) {
                        "+"
                    } else {
                        "-"
                    },
                    map.name,
                    map.status
                ),
                Style::default()
                    .fg(Color::Magenta)
                    .add_modifier(Modifier::BOLD),
            )
        }
        Entry::Ticket(map, ticket_index) => {
            let ticket = &app.maps[*map].tickets[*ticket_index];
            (
                format!(
                    "  {} {} [{}] {}",
                    if app
                        .collapsed
                        .contains(&format!("ticket:{map}:{ticket_index}"))
                    {
                        "+"
                    } else {
                        "-"
                    },
                    ticket.id,
                    ticket.status,
                    ticket.title
                ),
                Style::default().fg(status_color(&ticket.status)),
            )
        }
        Entry::Relationship(index, evidence) => {
            let goal = &app.goals[*index];
            (
                format!("    {} goal G{:02}: {}", evidence, goal.id, goal.slug),
                Style::default().fg(if evidence == "linked" {
                    Color::Cyan
                } else {
                    Color::DarkGray
                }),
            )
        }
        Entry::File(_, label) => (label.clone(), Style::default().fg(Color::Cyan)),
    }
}

fn draw(frame: &mut Frame, app: &mut App) {
    let area = frame.area();
    let outer = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(5),
            Constraint::Length(2),
        ])
        .split(area);
    let tabs = [" 1 Goals ", " 2 Wayfinding "];
    let header = Paragraph::new(Line::from(vec![
        Span::styled(
            tabs[0],
            if app.tab == 0 {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Magenta)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            },
        ),
        Span::raw(" "),
        Span::styled(
            tabs[1],
            if app.tab == 1 {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Magenta)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            },
        ),
        Span::raw(format!("  {}", app.root.display())),
    ]))
    .block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::DarkGray)),
    );
    frame.render_widget(header, outer[0]);
    app.header_area = outer[0];
    let content = if area.width >= 100 {
        Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(44), Constraint::Percentage(56)])
            .split(outer[1])
    } else {
        Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Percentage(48), Constraint::Percentage(52)])
            .split(outer[1])
    };
    app.list_area = content[0];
    let items: Vec<ListItem> = app
        .entries
        .iter()
        .map(|entry| {
            let (text, style) = entry_line(app, entry);
            ListItem::new(Line::from(Span::styled(text, style)))
        })
        .collect();
    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(if app.tab == 0 {
                    " Goals "
                } else {
                    " Wayfinding "
                }),
        )
        .highlight_style(
            Style::default()
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("> ");
    let mut state = ListState::default()
        .with_selected(Some(app.selected))
        .with_offset(app.list_offset);
    frame.render_stateful_widget(list, content[0], &mut state);
    app.preview_area = content[1];
    let preview = app.detail_text(content[1].width.saturating_sub(2));
    let max_offset = u16::try_from(
        preview
            .lines
            .len()
            .saturating_sub(usize::from(content[1].height.saturating_sub(2))),
    )
    .unwrap_or(u16::MAX);
    app.preview_offset = app.preview_offset.min(max_offset);
    let detail = Paragraph::new(preview)
        .block(Block::default().borders(Borders::ALL).title(" Detail "))
        .wrap(Wrap { trim: false })
        .scroll((app.preview_offset, 0));
    frame.render_widget(detail, content[1]);
    let footer = Paragraph::new(vec![
        Line::from(" Enter: open in editor | Space: collapse | m: mdt | 1/2/Tab: switch | r: refresh | q: quit "),
        Line::from(" j/k or wheel: navigate | PgUp/PgDn or wheel on preview: scroll | Click: select/tab "),
    ])
    .style(Style::default().fg(Color::DarkGray));
    frame.render_widget(footer, outer[2]);
}

fn handle_mouse(app: &mut App, column: u16, row: u16) {
    if row > app.header_area.y && row < app.header_area.y.saturating_add(app.header_area.height) {
        if column >= app.header_area.x.saturating_add(1)
            && column < app.header_area.x.saturating_add(11)
        {
            app.tab = 0;
            app.rebuild();
        } else if column >= app.header_area.x.saturating_add(12)
            && column < app.header_area.x.saturating_add(28)
        {
            app.tab = 1;
            app.rebuild();
        }
        return;
    }
    if column < app.list_area.x
        || column >= app.list_area.x.saturating_add(app.list_area.width)
        || row <= app.list_area.y
        || row
            >= app
                .list_area
                .y
                .saturating_add(app.list_area.height)
                .saturating_sub(1)
    {
        return;
    }
    let index = app.list_offset + usize::from(row.saturating_sub(app.list_area.y + 1));
    if index < app.entries.len() {
        app.select(index);
    }
}

fn handle_wheel(app: &mut App, column: u16, row: u16, down: bool) {
    if column >= app.list_area.x
        && column < app.list_area.x.saturating_add(app.list_area.width)
        && row > app.list_area.y
        && row < app.list_area.y.saturating_add(app.list_area.height)
    {
        if !app.repeat_throttle(if down { KeyCode::Down } else { KeyCode::Up }) {
            app.move_selection(if down { 1 } else { -1 });
        }
        return;
    }
    if column < app.preview_area.x
        || column >= app.preview_area.x.saturating_add(app.preview_area.width)
        || row < app.preview_area.y
        || row >= app.preview_area.y.saturating_add(app.preview_area.height)
    {
        return;
    }
    if !app.repeat_throttle(if down {
        KeyCode::PageDown
    } else {
        KeyCode::PageUp
    }) {
        if down {
            app.preview_offset = app.preview_offset.saturating_add(3);
        } else {
            app.preview_offset = app.preview_offset.saturating_sub(3);
        }
    }
}

fn open_mdt(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    path: &Path,
) -> Result<(), Box<dyn Error>> {
    if path.extension().and_then(|extension| extension.to_str()) != Some("md") {
        return Ok(());
    }
    let mut command = Command::new("mdt");
    command.arg(path);
    run_inline(terminal, command)
}

fn run(
    mut terminal: Terminal<CrosstermBackend<io::Stdout>>,
    mut app: App,
) -> Result<(), Box<dyn Error>> {
    loop {
        terminal.draw(|frame| draw(frame, &mut app))?;
        if !event::poll(Duration::from_millis(250))? {
            continue;
        }
        match event::read()? {
            Event::Key(key) if key.kind == KeyEventKind::Press => match key.code {
                KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                KeyCode::Down => {
                    if !app.repeat_throttle(KeyCode::Down) {
                        app.move_selection(1);
                    }
                }
                KeyCode::Char('j') => {
                    if !app.repeat_throttle(KeyCode::Char('j')) {
                        app.move_selection(1);
                    }
                }
                KeyCode::Up => {
                    if !app.repeat_throttle(KeyCode::Up) {
                        app.move_selection(-1);
                    }
                }
                KeyCode::Char('k') => {
                    if !app.repeat_throttle(KeyCode::Char('k')) {
                        app.move_selection(-1);
                    }
                }
                KeyCode::PageDown => {
                    if !app.repeat_throttle(KeyCode::PageDown) {
                        app.preview_offset = app
                            .preview_offset
                            .saturating_add(app.preview_area.height.saturating_sub(2))
                    }
                }
                KeyCode::PageUp => {
                    if !app.repeat_throttle(KeyCode::PageUp) {
                        app.preview_offset = app
                            .preview_offset
                            .saturating_sub(app.preview_area.height.saturating_sub(2))
                    }
                }
                KeyCode::Enter => app.enter(&mut terminal)?,
                KeyCode::Char(' ') => app.toggle_selected(),
                KeyCode::Tab | KeyCode::Right => {
                    app.tab = 1 - app.tab;
                    app.rebuild();
                }
                KeyCode::BackTab | KeyCode::Left => {
                    app.tab = 1 - app.tab;
                    app.rebuild();
                }
                KeyCode::Char('1') => {
                    app.tab = 0;
                    app.rebuild();
                }
                KeyCode::Char('2') => {
                    app.tab = 1;
                    app.rebuild();
                }
                KeyCode::Char('m') => {
                    if let Some(path) = app.selected_file() {
                        open_mdt(&mut terminal, &path)?;
                    }
                }
                KeyCode::Char('r') => {
                    app = App::new(app.root.clone());
                }
                _ => {}
            },
            Event::Mouse(mouse)
                if matches!(mouse.kind, MouseEventKind::Down(MouseButton::Left)) =>
            {
                handle_mouse(&mut app, mouse.column, mouse.row);
            }
            Event::Mouse(mouse) if matches!(mouse.kind, MouseEventKind::ScrollDown) => {
                handle_wheel(&mut app, mouse.column, mouse.row, true);
            }
            Event::Mouse(mouse) if matches!(mouse.kind, MouseEventKind::ScrollUp) => {
                handle_wheel(&mut app, mouse.column, mouse.row, false);
            }
            _ => {}
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let root = env::args()
        .nth(1)
        .ok_or("usage: goals-tui <project-root>")?;
    enable_raw_mode()?;
    execute!(stdout(), EnterAlternateScreen, EnableMouseCapture)?;
    let terminal = Terminal::new(CrosstermBackend::new(stdout()))?;
    let result = run(terminal, App::new(PathBuf::from(root)));
    disable_raw_mode()?;
    execute!(stdout(), DisableMouseCapture, LeaveAlternateScreen)?;
    result
}
