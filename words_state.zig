const std = @import("std");
const word_state = @import("word_state.zig");
const color = @import("color.zig");
const WordState = word_state.WordState;
const CharState = word_state.CharState;
const Color = color.Color;

pub const ALL_WORDS = [_][]const u8{ "the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "no", "just", "him", "know", "take", "people", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us", "is", "was", "are", "been", "has", "had", "were", "said", "did", "having", "may", "should", "am", "being", "able", "might", "must", "shall", "making", "seemed", "seems", "does", "done", "doing", "made", "makes", "find", "found", "finding", "finds", "call", "called", "calling", "calls", "ask", "asked", "asking", "asks", "try", "tried", "trying", "tries", "feel", "felt", "feeling", "feels", "leave", "left", "leaving", "leaves", "put", "puts", "putting", "mean", "meant", "meaning", "means", "keep", "kept", "keeping", "keeps", "let", "lets", "letting", "begin", "began", "begun", "beginning", "begins", "seem", "help", "helped", "helping", "helps", "show", "showed", "shown", "showing", "shows", "hear", "heard", "hearing", "hears", "play", "played", "playing", "plays", "run", "ran", "running", "runs", "move", "moved", "moving", "moves", "live", "lived", "living", "lives", "believe", "believed", "believing", "believes", "bring", "brought", "bringing", "brings", "happen", "happened", "happening", "happens", "write", "wrote", "written", "writing", "writes", "sit", "sat", "sitting", "sits", "stand", "stood", "standing", "stands", "lose", "lost", "losing", "loses", "pay", "paid", "paying", "pays", "meet", "met", "meeting", "meets", "include", "included", "including", "includes", "continue", "continued", "continuing", "continues", "set", "setting", "sets", "learn", "learned", "learning", "learns", "change", "changed", "changing", "changes", "lead", "led", "leading", "leads", "understand", "understood", "understanding", "understands", "watch", "watched", "watching", "watches", "follow", "followed", "following", "follows", "stop", "stopped", "stopping", "stops", "create", "created", "creating", "creates", "speak", "spoke", "spoken", "speaking", "speaks", "read", "reading", "reads", "allow", "allowed", "allowing", "allows", "add", "added", "adding", "adds", "spend", "spent", "spending", "spends", "grow", "grew", "grown", "growing", "grows", "open", "opened", "opening", "opens", "walk", "walked", "walking", "walks", "win", "won", "winning", "wins", "offer", "offered", "offering", "offers", "remember", "remembered", "remembering", "remembers", "love", "loved", "loving", "loves", "consider", "considered", "considering", "considers", "appear", "appeared", "appearing", "appears", "buy", "bought", "buying", "buys", "wait", "waited", "waiting", "waits", "serve", "served", "serving", "serves", "die", "died", "dying", "dies", "send", "sent", "sending", "sends", "expect", "expected", "expecting", "expects", "build", "built", "building", "builds", "stay", "stayed", "staying", "stays", "fall", "fell", "fallen", "falling", "falls", "cut", "cutting", "cuts", "reach", "reached", "reaching", "reaches", "kill", "killed", "killing", "kills", "raise", "raised", "raising", "raises", "pass", "passed", "passing", "passes", "sell", "sold", "selling", "sells", "require", "required", "requiring", "requires", "report", "reported", "reporting", "reports", "decide", "decided", "deciding", "decides", "pull", "pulled", "pulling", "pulls", "man", "woman", "child", "person", "world", "life", "hand", "part", "place", "case", "week", "company", "system", "program", "question", "work", "government", "number", "night", "point", "home", "water", "room", "mother", "area", "money", "story", "fact", "month", "lot", "right", "study", "book", "eye", "job", "word", "business", "issue", "side", "kind", "head", "house", "service", "friend", "father", "power", "hour", "game", "line", "end", "member", "law", "car", "city", "community", "name", "president", "team", "minute", "idea", "kid", "body", "information", "nothing", "ago", "right", "lead", "social", "understand", "whether", "back", "watch", "together", "follow", "around", "parent", "only", "stop", "face", "anything", "create", "public", "already", "speak", "others", "read", "level", "allow", "office", "spend", "door", "health", "person", "art", "sure", "such", "war", "history", "party", "within", "grow", "result", "open", "change", "morning", "walk", "reason", "low", "win", "research", "girl", "guy", "early", "food", "before", "moment", "himself", "air", "teacher", "force", "offer", "enough", "both", "across", "although", "remember", "foot", "second", "boy", "maybe", "toward", "able", "age", "off", "policy", "everything", "love", "process", "music", "including", "consider", "appear", "actually", "buy", "probably", "human", "wait", "serve", "market", "die", "send", "expect", "home", "sense", "build", "stay", "fall", "nation", "plan", "cut", "college", "interest", "death", "course", "someone", "experience", "behind", "reach", "local", "kill", "six", "remain", "effect", "use", "yeah", "suggest", "class", "control", "raise", "care", "perhaps", "little", "late", "hard", "field", "else", "pass", "former", "sell", "major", "sometimes", "require", "along", "development", "themselves", "report", "role", "better", "economic", "effort", "up", "decide", "rate", "strong", "possible", "heart", "drug", "show", "leader", "light", "voice", "wife", "whole", "police", "mind", "finally", "pull", "return", "free", "military", "price", "less", "according", "decision", "explain", "son", "hope", "even", "develop", "view", "relationship", "carry", "town", "road", "drive", "arm", "true", "federal", "break", "better", "difference", "thank", "receive", "value", "international", "building", "action", "full", "model", "join", "season", "society", "because", "tax", "director", "early", "position", "player", "agree", "especially", "record", "pick", "wear", "paper", "special", "space", "ground", "form", "support", "event", "official", "whose", "matter", "everyone", "center", "couple", "site", "end", "project", "hit", "base", "activity", "star", "table", "need", "court", "produce", "eat", "american", "teach", "oil", "half", "situation", "easy", "cost", "industry", "figure", "face", "street", "image", "itself", "phone", "either", "data", "cover", "quite", "picture", "clear", "practice", "piece", "land", "recent", "describe", "product", "doctor", "wall", "patient", "worker", "news", "test", "movie", "certain", "north", "love", "personal", "open", "support", "simply", "third", "technology", "catch", "step", "baby", "computer", "type", "attention", "draw", "film", "republican", "tree", "source", "red", "nearly", "organization", "choose", "cause", "hair", "look", "point", "century", "evidence", "window", "difficult", "listen", "soon", "culture", "billion", "chance", "brother", "energy", "period", "course", "summer", "less", "realize", "hundred", "available", "plant", "likely", "opportunity", "term", "short", "letter", "condition", "choice", "place", "single", "rule", "daughter", "administration", "south", "husband", "congress", "floor", "campaign", "material", "population", "well", "call", "economy", "medical", "hospital", "church", "close", "thousand", "risk", "current", "fire", "future", "wrong", "involve", "defense", "anyone", "increase", "security", "bank", "myself", "certainly", "west", "sport", "board", "seek", "per", "subject", "officer", "private", "rest", "behavior", "deal", "performance", "fight", "throw", "top", "quickly", "past", "goal", "second", "bed", "order", "author", "fill", "represent", "focus", "foreign", "drop", "plan", "blood", "upon", "agency", "push", "nature", "color", "no", "recently", "store", "reduce", "sound", "note", "fine", "before", "near", "movement", "page", "enter", "share", "than", "common", "poor", "other", "natural", "race", "concern", "series", "significant", "similar", "hot", "language", "each", "usually", "response", "dead", "rise", "animal", "factor", "decade", "article", "shoot", "east", "save", "seven", "artist", "away", "scene", "stock", "career", "despite", "central", "eight", "thus", "treatment", "beyond", "happy", "exactly", "protect", "approach", "lie", "size", "dog", "fund", "serious", "occur", "media", "ready", "sign", "thought", "list", "individual", "simple", "quality", "pressure", "accept", "answer", "hard", "resource", "identify", "left", "meeting", "determine", "prepare", "disease", "whatever", "success", "argue", "cup", "particularly", "amount", "ability", "staff", "recognize", "indicate", "character", "growth", "loss", "degree", "wonder", "attack", "herself", "region", "television", "box", "tv", "training", "pretty", "trade", "deal", "election", "everybody", "physical", "lay", "general", "feeling", "standard", "bill", "message", "fail", "outside", "arrive", "analysis", "benefit", "name", "sex", "forward", "lawyer", "present", "section", "environmental", "glass", "answer", "skill", "sister", "pm", "professor", "operation", "financial", "crime", "stage", "ok", "compare", "authority", "miss", "design", "sort", "one", "act", "ten", "knowledge", "gun", "station", "blue", "state", "strategy", "little", "clearly", "discuss", "indeed", "force", "truth", "song", "example", "democratic", "check", "environment", "leg", "dark", "public", "various", "rather", "laugh", "guess", "executive", "set", "study", "prove", "hang", "entire", "rock", "design", "enough", "forget", "since", "claim", "note", "remove", "manager", "help", "close", "sound", "enjoy", "network", "legal", "religious", "cold", "form", "final", "main", "science", "green", "memory", "card", "above", "seat", "cell", "establish", "nice", "trial", "expert", "that", "spring", "firm", "democrat", "radio", "visit", "management", "care", "avoid", "imagine", "tonight", "huge", "ball", "no", "close", "finish", "yourself", "talk", "theory", "impact", "respond", "statement", "maintain", "charge", "popular", "traditional", "onto", "reveal", "direction", "weapon", "employee", "cultural", "contain", "peace", "head", "control", "base", "pain", "apply", "play", "measure", "wide", "shake", "fly", "interview", "manage", "chair", "fish", "particular", "camera", "structure", "politics", "perform", "bit", "weight", "suddenly", "discover", "candidate", "top", "production", "treat", "trip", "evening", "affect", "inside", "conference", "unit", "best", "style", "adult", "worry", "range", "mention", "rather", "far", "deep", "past", "edge", "individual", "specific", "writer", "trouble", "necessary", "throughout", "challenge", "fear", "shoulder", "institution", "middle", "sea", "dream", "bar", "beautiful", "property", "instead", "improve", "stuff", "claim", "zig", "software", "ai", "none", "fast", "blazingly", "update", "upgrade", "publication", "contact", "hobby", "intervention", "discovery", "volcano", "trait", "criminal", "nerve", "dialect", "mutual", "terrace", "lace", "tile", "tie", "exploit", "ancestor", "exchange", "appreciate", "detective", "disagreement", "excavate", "experienced" };
pub const TOTAL_CHARS: comptime_int = blk: {
    @setEvalBranchQuota(10000);
    var total_len = 0;
    for (ALL_WORDS) |word| {
        total_len += word.len;
    }
    break :blk total_len;
};
pub const AVG_CHAR_PER_WORD: comptime_float = @as(f64, @floatFromInt(TOTAL_CHARS)) / @as(f64, @floatFromInt(ALL_WORDS.len));

pub fn getRandomWords(allocator: std.mem.Allocator, n: usize) ![][]const u8 {
    // Generate random seed and create RNG (classic PNRG instead of CSPRNG)
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random: std.Random = prng.random();

    const result: [][]const u8 = try allocator.alloc([]const u8, n);
    for (result, 0..) |_, i| {
        const random_index = random.intRangeAtMost(usize, 0, ALL_WORDS.len - 1);
        result[i] = ALL_WORDS[random_index];
    }
    return result;
}

pub const WordsState = struct {
    word_states: []WordState,
    word_slices: [][]const u8,
    total_length: usize,

    pub fn getAvgCharPerWord(self: *const WordsState) f64 {
        var total_chars: usize = 0;
        for (self.word_slices) |word| {
            total_chars += word.len;
        }
        return @as(f64, @floatFromInt(total_chars)) / @as(f64, @floatFromInt(self.word_slices.len));
    }
    pub fn getPartiallyValidWords(self: *const WordsState) usize {
        var partialWords: usize = 0;
        for (self.word_states) |ws| {
            if (ws.isPartiallyValid()) partialWords += 1;
        }
        return partialWords;
    }
    pub fn getValidWords(self: *const WordsState) usize {
        var validWords: usize = 0;
        for (self.word_states) |ws| {
            if (ws.isValid()) validWords += 1;
        }
        return validWords;
    }
    pub fn wordIndexValid(self: *const WordsState, word_idx: usize) bool {
        return 0 <= word_idx and word_idx < self.word_slices.len;
    }

    pub fn getWordState(self: *const WordsState, word_idx: usize) !*const WordState {
        if (!self.wordIndexValid(word_idx)) return error.IndexOutOfBounds;
        return &self.word_states[word_idx];
    }

    pub fn removeLastOverflow(self: *const WordsState, word_idx: usize) !void {
        if (!self.wordIndexValid(word_idx)) return error.IndexOutOfBounds;
        try self.word_states[word_idx].removeLastOverflow();
    }

    pub fn setCharStateAt(self: *const WordsState, word_idx: usize, char_idx: usize, char_state: CharState) !void {
        if (!self.wordIndexValid(word_idx)) return error.IndexOutOfBounds;
        return self.word_states[word_idx].setCharStateAt(char_idx, char_state);
    }

    pub fn getLastCharIdxToFill(self: *const WordsState, word_idx: usize) usize {
        if (0 <= word_idx and word_idx < self.word_states.len) return 0;
        const new_char_idx = if (self.getWordState(word_idx)) |ws| ws.getLastCharIdxToFill() else |_| 0;
        return new_char_idx;
    }

    pub fn init(allocator: std.mem.Allocator, number_of_words: usize) !WordsState {
        const word_slices: [][]const u8 = try getRandomWords(allocator, number_of_words);
        errdefer allocator.free(word_slices);
        const word_states: []WordState = try allocator.alloc(WordState, number_of_words);
        errdefer allocator.free(word_states);

        for (word_states, 0..) |*word_state_ptr, i| {
            word_state_ptr.* = try WordState.init(allocator, word_slices[i]);
        }

        return WordsState{
            .word_states = word_states,
            .word_slices = word_slices,
            .total_length = blk: {
                var l: usize = 0;
                // getting all the characters
                for (word_slices) |word_slice| {
                    l += word_slice.len;
                }
                // getting all the spaces
                l += word_states.len - 1;
                break :blk l;
            },
        };
    }

    pub fn deinit(self: *WordsState, allocator: std.mem.Allocator) void {
        for (self.word_states) |*word_state_ptr| {
            word_state_ptr.deinit(allocator);
        }
        allocator.free(self.word_states);
        allocator.free(self.word_slices);
    }
    pub fn isSentenceDone(self: *const WordsState) bool {
       return self.word_states[self.word_slices.len - 1].doesWordEndWithValidatedChar();
    }

    pub fn print(self: *const WordsState, word_idx: usize, char_idx: usize) void {
        std.debug.print("\x1b[?25l", .{}); // Hide cursor

        // Clear entire line and go to beginning
        std.debug.print("\x1b[2K\x1b[G", .{});

        // Print all words with correct colors
        for (self.word_slices, 0..) |word_slice, word_idx_l| {
            for (word_slice, 0..) |char, char_idx_l| {
                const char_color: Color = switch (self.word_states[word_idx_l].char_states[char_idx_l]) {
                    .toComplete => .gray,
                    .valid => .correct,
                    .invalid => .error_fg,
                };
                color.printColoredChar(char_color, char);
            }

            // Print overflow characters for current word
            if (word_idx_l == word_idx) {
                for (self.word_states[word_idx_l].overflow) |overflow_char| {
                    if (overflow_char != 0) {
                        color.printColoredChar(.error_bg, overflow_char);
                    }
                }
            }

            if (word_idx_l < self.word_slices.len - 1) {
                color.printColoredChar(Color.gray, ' ');
            }
        }

        // Calculate cursor position and move there
        var cursor_pos: usize = 0;
        for (0..word_idx) |i| {
            cursor_pos += self.word_slices[i].len + 1; // +1 for space
        }
        cursor_pos += char_idx;

        // Move to cursor position and show cursor
        std.debug.print("\x1b[G\x1b[{}C\x1b[?25h", .{cursor_pos});
    }

    pub fn print0(self: *const WordsState) void {
        for (self.word_slices, 0..) |word_slice, word_idx_l| {
            for (word_slice) |char| {
                color.printColoredChar(.gray, char);
            }
            if (word_idx_l < self.word_slices.len - 1) {
                color.printColoredChar(Color.gray, ' ');
            }
        }
    }
};