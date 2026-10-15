local XUiPacMan2EventDefine = {}

---原子事件类型。
---必须与PacMan2AtomicEvent.EventType中的字符串完全一致。
XUiPacMan2EventDefine.AtomicType = {
    Dialogue = "Dialogue",
    Sound = "Sound",
    Bgm = "Bgm",
    MagicFilter = "MagicFilter",
    EndingMask = "EndingMask",
    Overlay = "Overlay",
    OverlayDialogue = "OverlayDialogue",
}

---音效操作类型。
XUiPacMan2EventDefine.SoundAction = {
    PlayOnce = 1,
    LoopStart = 2,
    LoopStop = 3,
}

---BGM操作类型。
XUiPacMan2EventDefine.BgmAction = {
    Play = 1,
    ChangeTrack = 2,
}

---BGM变轨状态。
XUiPacMan2EventDefine.BgmTrackState = {
    Normal = 1,
    Drum = 2,
}

---对话显示类型。
---Game兼容接口、原子事件执行器和表现控制器共用，避免各自使用数字约定。
XUiPacMan2EventDefine.DialogType = {
    Text = 1,
    Character = 2,
}

---倒计时完成通知的来源。
---Game、EventRuntime和ContextUpdater共用这套约定。
---仅用于Lua内部通知，策划仍通过三个独立条件字段配置。
XUiPacMan2EventDefine.CountdownSource = {
    Opening = 1,
    DamageRecovery = 2,
    Restart = 3,
}
return XUiPacMan2EventDefine