## Problem
Pushing an MVVM feature from a TCA feature and sending data back to the TCA feature via a closure requires a long running Effect using an AsyncStream. When the MVVM feature pops off the stack, this AsyncStream fails to cancel and keeps the MVVM feature's ViewModel in memory.

### Steps To Reproduce
1. Launch app and tap "Push MVVM Feature" button.
2. Increment count in MVVM feature
3. Tap "Send data back to TCA" button
4. The MVVM feature will get popped off the stack, the count in the TCA feature will be the same as the MVVM feature.
5. Observe in the debug console that "Stream cancelled" was never printed, indicating the `for await` loop was never exited.
6. Open memory graph to see ViewModel is still in memory.
7. Tap the "Push MVVM Feature" button again and pop off the stack to go back to TCA again (doesn't matter how).
8. Open memory graph again to now see 2 ViewModels in memory.
