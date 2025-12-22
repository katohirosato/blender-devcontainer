// {/* <script type="module">import "./clipboard.mjs";</script> */}
// cp novnc_setup/clipboard.mjs .devcontainer/novnc/public/noVNC/clipboard.mjs

document.addEventListener('keydown', async function(e) {
    if (e.ctrlKey) {
        if (e.code === 'KeyC') {
            const text = document.querySelector('#noVNC_clipboard_text').value;
            await navigator.clipboard.writeText(text);
            return;
        }
        const clipText = await navigator.clipboard.readText();
        document.querySelector('#noVNC_clipboard_text').value = clipText;
        document.querySelector('#noVNC_clipboard_text').dispatchEvent(new Event('change'));
    }
},{capture:true, passive: true});

setInterval(async function() {
    if (!document.hasFocus()) return;
    try {
        const clipText = await navigator.clipboard.readText();
        document.querySelector('#noVNC_clipboard_text').value = clipText;
        document.querySelector('#noVNC_clipboard_text').dispatchEvent(new Event('change'));
    } catch (err) {
        console.error('Failed to read clipboard contents: ', err);
    }
}, 100);