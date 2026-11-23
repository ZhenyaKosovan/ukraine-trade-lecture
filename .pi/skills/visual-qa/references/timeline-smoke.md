# Lecture timeline smoke test

Use this payload with Pi's native `agent_browser`. Resolve the `file://` URL to the rendered `deck/lecture.html` in the worktree you want to test. Use a unique screenshot path if saving another run. This safely reopens a local deck, checks the fullscreen state of the iframe, and tests a timeline transition. It does not test native wheel input.

```json
{
  "args": ["batch", "--bail"],
  "stdin": "[[\"open\",\"file:///home/zhenya/ukraine-trade-lecture/deck/lecture.html#/timeline\"],[\"wait\",\"--fn\",\"location.hash === '#/timeline' && document.querySelector('.history-frame')?.contentDocument?.querySelector('.cr-active')?.id === 'cr-independence'\",\"--timeout\",\"5000\"],[\"find\",\"role\",\"button\",\"click\",\"--name\",\"Expand timeline\"],[\"wait\",\"--fn\",\"(()=>{const f=document.querySelector('.history-frame');return !!f && document.fullscreenElement===f && !!f.contentDocument?.querySelector('button[aria-label=\\\"Close expanded timeline\\\"]')?.getClientRects().length;})()\",\"--timeout\",\"3000\"],[\"eval\",\"(()=>{const f=document.querySelector('.history-frame'),w=f.contentWindow,t=[...f.contentDocument.querySelectorAll('.new-trigger')].find(n=>n.dataset.focusOn==='cr-belovezha'); window.qaStartScroll=w.scrollY;w.scrollTo(0,w.scrollY+t.getBoundingClientRect().top+(t.offsetHeight-w.innerHeight)/2);})()\"],[\"wait\",\"--fn\",\"(()=>{const f=document.querySelector('.history-frame');return Reveal.getCurrentSlide().id==='timeline' && f.contentWindow.scrollY>window.qaStartScroll && f.contentDocument.querySelector('.cr-active')?.id==='cr-belovezha';})()\",\"--timeout\",\"3000\"],[\"eval\",\"({slide:Reveal.getCurrentSlide().id,active:document.querySelector('.history-frame').contentDocument.querySelector('.cr-active').id,initialY:window.qaStartScroll,finalY:document.querySelector('.history-frame').contentWindow.scrollY})\"],[\"screenshot\",\"/tmp/ukraine-lecture-browser-qa-verified.png\"]]"
}
```

A pass reports `slide: "timeline"`, `active: "cr-belovezha"` and `finalY > initialY`, then verifies the screenshot artifact. If the batch fails, locate the first failing step. `--bail` stops before the screenshot when an assertion fails. An older image at that path is not evidence of a pass.
