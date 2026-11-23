---
name: visual-qa
description: Review rendered presentations and dashboards for layout, readability, chart, and interaction issues. Use for visual QA of slide decks, PDF exports, and live dashboards.
---

# Visual QA

Use an image-capable model. Inspect rendered screenshots before reviewing source. A browser snapshot helps locate controls but does not replace an image. If image input is unavailable, report that limitation and do not claim a visual review.

- **Presentations:** Capture each slide at the intended presentation size. Review the exported PDF separately by rendering each page to a PNG. Check for clipped content, overlapping labels, and text or legends that are too small to read at presentation size.
- **Dashboards:** Use `agent_browser` to capture desktop and mobile viewports. Exercise relevant filters, selections, tooltips, and empty states. Wait for the intended data and charts to render before capturing. Check for overflow, unclear filter states, unreadable charts, and keyboard and touch problems.
- Open saved PNGs with `read`. Inspect viewport-sized captures or crops if a long screenshot is downscaled and details become hard to read.
- Check that charts show their units, have readable legends, and distinguish missing data from zero where relevant. Verify suspected clipping or low contrast with browser measurements when possible. Test interaction claims in the live UI rather than inferring them from screenshots.

## Browser interaction checks

- For a repeatable slide or dashboard test, use one native `agent_browser` `job` with open, readiness, exact role/name action, and a postcondition. Capture the screenshot after the postcondition. A successful click or screenshot alone does not verify the interaction.
- If a control from the latest snapshot fails, check `tab list` before reporting a missing UI element. If the only tab is `about:blank`, reopen and run the check in one job. Do not reset a stateful flow just to retry a click.
- For the lecture timeline, use the [timeline smoke test](references/timeline-smoke.md). It asserts actual iframe fullscreen and the visible **Close expanded timeline** control, then verifies that the frame scrolled, `.cr-active` changed from `cr-independence` to `cr-belovezha`, and Reveal stayed on `timeline`. This is a programmatic scroll test. Native wheel coverage requires the wheel event to reach the frame and move it; `scrolled: true` is not enough.

Report findings in severity order. For each, give the slide or UI state, viewport or export size, screenshot path, observed issue, user impact, and suggested fix. Distinguish confirmed defects from design suggestions and say what you did not test.

Do not edit unless asked. After a fix, recapture the same state and verify it.
