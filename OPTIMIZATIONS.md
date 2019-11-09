- Reduce number of re-renders
  - Every component with state causes a rerender when state is initially set...
    - So opening a new overlay causes more than 1 render, when 1 should be enough
  - Opening new campground causes 7 renders
  - Closing campground page causes 5 renders


- Never set state to "isMounted" or "isVisible" in afterMount (for an animation)
  - just manually add the class in JS so as to not re-render entire page

- DONE Bottom bar ripple seems laggy

- Reduce complexity of $app render since that one is guaranteed called every time.
  - overlays, drawer to own component state
  - though it might only save ~1ms or less

- Figure out how to render just child components and not the whole page for a child component changing
  - Zorium would need to be rewritten a good bit, since the actual re-render
    is done on the bound element (App). It's optimized in the sense that if
    component state isn't dirty, it uses cached version
  - Once that's done, the most common change to "app" component state is adding overlay
    - Should not re-render entire app/page to add those overlays



- Keep components simple if possible (no state)
  - Will make it so vdom doesn't need to have unhook fn


- DONE Use modularized RxJS
- DONE, sort of (loading separate file) Figure out a solution to load CSS dynamically and see if it's faster?
- DONE Make own build of iscroll like iscroll-lite, but with snap
- Test using .publishReplay(1).refCount() in places where a mapped observable is subscribed to multiple times
- Unrelated to speed, need to swap localStorage with something else in native iOS app (gets cleared too often)
- Set user and groupUser in avatar header instead of as props
- https://github.com/IguMail/socketio-shared-webworker
- optimize FormattedMessage. markdown parser is slow (1-5ms per message)
