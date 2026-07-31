extends Node
# HighScoreManager
# Persists and retrieves the top 10 high scores based on days survived.

const SAVE_PATH := "user://highscores.cfg"
const MAX_ENTRIES := 10

static func load_scores() -> Array[Dictionary]:
    var file := ConfigFile.new()
    var err := file.load(SAVE_PATH)
    if err != OK:
        return []
    var scores: Array = file.get_value("highscores", "scores", [])
    return scores

static func _save_scores(scores: Array) -> void:
    var file := ConfigFile.new()
    file.set_value("highscores", "scores", scores)
    var err := file.save(SAVE_PATH)
    if err != OK:
        push_warning("HighScoreManager: failed to save highscores, error=%d" % err)

static func get_top_10() -> Array[Dictionary]:
    var scores := load_scores()
    scores.sort_custom(func(a, b): return int(a.get("day", 0)) > int(b.get("day", 0)))
    return scores.slice(0, MAX_ENTRIES)

static func save_score(day: int) -> void:
    var scores := load_scores()
    scores.append({
        "day": day,
        "date": Time.get_date_string_from_system()
    })
    scores.sort_custom(func(a, b): return int(a.get("day", 0)) > int(b.get("day", 0)))
    scores = scores.slice(0, MAX_ENTRIES)
    _save_scores(scores)
