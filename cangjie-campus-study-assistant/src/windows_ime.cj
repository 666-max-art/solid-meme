package studymate

foreign {
    func SDL_GetWindows(count: CPointer<Int32>): CPointer<CPointer<Unit>>
    func SDL_GetWindowProperties(window: CPointer<Unit>): UInt32
    func SDL_GetPointerProperty(properties: UInt32, name: CString, fallback: CPointer<Unit>): CPointer<Unit>
    func SDL_TextInputActive(window: CPointer<Unit>): Bool
    func SDL_free(memory: CPointer<Unit>): Unit
    func SDL_LoadObject(path: CString): CPointer<Unit>
    func SDL_LoadFunction(library: CPointer<Unit>, name: CString): CPointer<Unit>
    func SDL_UnloadObject(library: CPointer<Unit>): Unit
}

// 在 DesktopApp 构造后使用，调用始终留在已经绑定的窗口线程。
// 恢复窗口的系统输入法上下文；是否能实际输入中文仍需宿主桌面验证。
@When[os == "Windows"]
class WindowsTextInput <: Resource {
    private let ownerThread = Thread.currentThread.id
    private var library = CPointer<Unit>()
    private var window = CPointer<Unit>()
    private var hwnd = CPointer<Unit>()
    private var ownedContext = CPointer<Unit>()
    private var getContext = CPointer<Unit>()
    private var releaseContext = CPointer<Unit>()
    private var associateDefault = CPointer<Unit>()
    private var createContext = CPointer<Unit>()
    private var associateContext = CPointer<Unit>()
    private var destroyContext = CPointer<Unit>()
    private var initialContext = false
    private var restored = false
    private var defaultAttempted = false
    private var lastDefaultResult: Int32 = 0
    private var closed = false
    private var failure = ""

    init() {
        let dllName = unsafe { LibC.mallocCString("imm32.dll") }
        try (name = dllName.asResource()) {
            library = unsafe { SDL_LoadObject(name.value) }
        }
        if (library.isNull()) {
            throw IllegalStateException("无法加载 Windows 输入法服务 imm32.dll")
        }
        try {
            getContext = symbol("ImmGetContext")
            releaseContext = symbol("ImmReleaseContext")
            associateDefault = symbol("ImmAssociateContextEx")
            createContext = symbol("ImmCreateContext")
            associateContext = symbol("ImmAssociateContext")
            destroyContext = symbol("ImmDestroyContext")
            window = findOwnWindow()
            let propertyName = unsafe { LibC.mallocCString("SDL.window.win32.hwnd") }
            try (name = propertyName.asResource()) {
                let properties = unsafe { SDL_GetWindowProperties(window) }
                if (properties == 0) {
                    throw IllegalStateException("无法读取学伴窗口的 SDL 属性")
                }
                hwnd = unsafe { SDL_GetPointerProperty(properties, name.value, CPointer<Unit>()) }
            }
            if (hwnd.isNull()) {
                throw IllegalStateException("无法取得学伴窗口的 Windows 句柄")
            }
            initialContext = contextPresent()
        } catch (error: Exception) {
            unsafe { SDL_UnloadObject(library) }
            library = CPointer<Unit>()
            throw error
        }
    }

    // SDL 重新获得窗口焦点时可能再次解除关联，所以在帧回调中按需检查。
    // 已有上下文时立即返回，避免打断正在进行的中文组合输入。
    public func ensure(): Unit {
        ensureOpen()
        if (contextPresent()) {
            return
        }
        defaultAttempted = true
        lastDefaultResult = unsafe {
            CFunc<(CPointer<Unit>, CPointer<Unit>, UInt32) -> Int32>(associateDefault)(
                hwnd, CPointer<Unit>(), UInt32(0x10)) // IACE_DEFAULT
        }
        if (contextPresent()) {
            restored = true
            failure = ""
            return
        }

        // 默认上下文不可用时才创建一个；窗口失焦后复用自己持有的上下文。
        if (ownedContext.isNull()) {
            ownedContext = unsafe { CFunc<() -> CPointer<Unit>>(createContext)() }
            if (ownedContext.isNull()) {
                fail("Windows 未提供默认输入法上下文，创建新上下文也失败")
            }
        }
        let _ = unsafe {
            CFunc<(CPointer<Unit>, CPointer<Unit>) -> CPointer<Unit>>(associateContext)(hwnd, ownedContext)
        }
        if (!contextPresent()) {
            fail("已创建输入法上下文，但无法关联到学伴窗口")
        }
        restored = true
        failure = ""
    }

    // 只报告实际查询到的状态；context=true 不等于已经验证中文候选及提交。
    public func diagnostics(): String {
        if (closed) {
            return "Windows IME: closed=true; initial=${initialContext}; restored=${restored}; failure=${failure}"
        }
        ensureOpen()
        let currentContext = contextPresent()
        let textActive = unsafe { SDL_TextInputActive(window) }
        "Windows IME: initial=${initialContext}; restored=${restored}; context=${currentContext}; " +
            "owned=${ownedContext.isNotNull()}; defaultAttempted=${defaultAttempted}; " +
            "defaultResult=${lastDefaultResult}; SDL_TextInputActive=${textActive}; failure=${failure}"
    }

    public func isClosed(): Bool { closed }

    // app.manage 的关闭顺序保证这里执行时 SDL 窗口尚未销毁。
    // 默认上下文属于系统，只释放查询引用；仅销毁自己创建的上下文。
    public func close(): Unit {
        if (closed) { return }
        ensureOpen()
        var closeFailure = ""
        try {
            if (ownedContext.isNotNull()) {
                let current = borrowContext()
                if (current.isNotNull()) {
                    releaseBorrowed(current)
                }
                if (current.toUIntNative() == ownedContext.toUIntNative()) {
                    let _ = unsafe {
                        CFunc<(CPointer<Unit>, CPointer<Unit>) -> CPointer<Unit>>(associateContext)(
                            hwnd, CPointer<Unit>())
                    }
                    if (contextPresent()) {
                        closeFailure = "无法解除学伴自建的输入法上下文；为避免悬空引用，保留该上下文"
                    }
                }
                if (closeFailure.isEmpty()) {
                    let destroyed = unsafe { CFunc<(CPointer<Unit>) -> Int32>(destroyContext)(ownedContext) }
                    if (destroyed == 0) {
                        closeFailure = "无法销毁学伴自建的输入法上下文"
                    } else {
                        ownedContext = CPointer<Unit>()
                    }
                }
            }
        } finally {
            closed = true
            if (library.isNotNull() && ownedContext.isNull()) {
                unsafe { SDL_UnloadObject(library) }
                library = CPointer<Unit>()
            }
        }
        if (!closeFailure.isEmpty()) {
            failure = closeFailure
            throw IllegalStateException(closeFailure)
        }
    }

    private func symbol(name: String): CPointer<Unit> {
        let text = unsafe { LibC.mallocCString(name) }
        var function = CPointer<Unit>()
        try (value = text.asResource()) {
            function = unsafe { SDL_LoadFunction(library, value.value) }
        }
        if (function.isNull()) {
            throw IllegalStateException("Windows 输入法服务缺少函数：${name}")
        }
        function
    }

    private func findOwnWindow(): CPointer<Unit> {
        var count: Int32 = 0
        let windows = unsafe { SDL_GetWindows(inout count) }
        if (windows.isNull()) {
            throw IllegalStateException("无法查询学伴的 SDL 窗口")
        }
        try {
            if (count != 1) {
                throw IllegalStateException("输入法修复需要唯一的学伴窗口，实际窗口数为 ${count}")
            }
            unsafe { windows.read() }
        } finally {
            unsafe { SDL_free(CPointer<Unit>(windows)) }
        }
    }

    private func borrowContext(): CPointer<Unit> {
        unsafe { CFunc<(CPointer<Unit>) -> CPointer<Unit>>(getContext)(hwnd) }
    }

    private func releaseBorrowed(context: CPointer<Unit>): Unit {
        let released = unsafe {
            CFunc<(CPointer<Unit>, CPointer<Unit>) -> Int32>(releaseContext)(hwnd, context)
        }
        if (released == 0) {
            fail("无法释放输入法上下文的查询引用")
        }
    }

    private func contextPresent(): Bool {
        let context = borrowContext()
        if (context.isNull()) { return false }
        releaseBorrowed(context)
        true
    }

    private func ensureOpen(): Unit {
        if (closed) { throw IllegalStateException("Windows 输入法适配器已经关闭") }
        if (Thread.currentThread.id != ownerThread) {
            throw IllegalStateException("输入法适配器必须由创建窗口的线程调用")
        }
    }

    private func fail(message: String): Unit {
        failure = message
        throw IllegalStateException(message)
    }
}
