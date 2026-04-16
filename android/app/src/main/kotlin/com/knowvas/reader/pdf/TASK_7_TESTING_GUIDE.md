# Task 7: Touch Handler Testing Guide

## Quick Test Checklist

Use this guide to manually verify the TouchHandler implementation on a device or emulator.

## Prerequisites

1. Build and run the app on a device or emulator
2. Open a PDF document in the reader
3. Ensure the PageCurlView is active

## Test Scenarios

### ✅ Test 1: Right Edge Touch (Forward Curl)

**Steps:**
1. Touch near the right edge of the page (within 20% of width)
2. Drag left across the page
3. Release

**Expected:**
- Curl should start when you touch the right edge
- Page should curl as you drag
- If you drag more than 30% of page width, page should turn forward
- If you drag less than 30%, page should snap back

**Visual Indicators:**
- Curl animation should be smooth
- Direction should be FORWARD (right to left)

### ✅ Test 2: Left Edge Touch (Backward Curl)

**Steps:**
1. Touch near the left edge of the page (within 20% of width)
2. Drag right across the page
3. Release

**Expected:**
- Curl should start when you touch the left edge
- Page should curl as you drag
- If you drag more than 30% of page width, page should turn backward
- If you drag less than 30%, page should snap back

**Visual Indicators:**
- Curl animation should be smooth
- Direction should be BACKWARD (left to right)

### ✅ Test 3: Center Touch (Should Be Ignored)

**Steps:**
1. Touch in the center of the page (not near edges)
2. Try to drag

**Expected:**
- No curl should start
- Touch should be ignored
- Page should remain flat

**Visual Indicators:**
- No visual feedback
- No curl animation

### ✅ Test 4: Page Turn Threshold

**Steps:**
1. Touch right edge
2. Drag left about 40% of page width
3. Release

**Expected:**
- Page should complete the turn automatically
- Animation should be smooth
- Next page should be displayed

**Visual Indicators:**
- Curl completes to full page turn
- Page change occurs

### ✅ Test 5: Snap Back

**Steps:**
1. Touch right edge
2. Drag left about 20% of page width (less than 30% threshold)
3. Release

**Expected:**
- Page should snap back to original position
- Animation should have elastic feel
- Same page should remain displayed

**Visual Indicators:**
- Curl reverses smoothly
- Page returns to flat state

### ✅ Test 6: Vertical Drag

**Steps:**
1. Touch right edge
2. Drag vertically (up or down) without much horizontal movement
3. Release

**Expected:**
- Curl should still work
- Vertical movement should be tracked
- Snap back should occur (not enough horizontal distance)

**Visual Indicators:**
- Curl follows vertical movement
- Smooth animation

### ✅ Test 7: Diagonal Drag

**Steps:**
1. Touch right edge
2. Drag diagonally (left and down, or left and up)
3. Release

**Expected:**
- Curl should follow diagonal path
- Total distance should be calculated correctly
- Page turn or snap back based on total distance

**Visual Indicators:**
- Curl follows diagonal movement
- Smooth animation

### ✅ Test 8: Corner Touch

**Steps:**
1. Touch top-right corner
2. Drag left
3. Release

**Expected:**
- Curl should start (corner is within edge threshold)
- Same behavior as right edge touch

**Visual Indicators:**
- Curl starts from corner
- Smooth animation

### ✅ Test 9: Quick Swipe

**Steps:**
1. Touch right edge
2. Quickly swipe left (fast gesture)
3. Release

**Expected:**
- Curl should track the fast movement
- If swipe distance > 30%, page should turn
- Animation should complete smoothly

**Visual Indicators:**
- Curl responds to fast movement
- No lag or stuttering

### ✅ Test 10: Slow Drag

**Steps:**
1. Touch right edge
2. Slowly drag left (very slow movement)
3. Release

**Expected:**
- Curl should track the slow movement
- Same threshold logic applies
- Smooth animation throughout

**Visual Indicators:**
- Curl follows slow movement precisely
- No jitter or jumping

## Edge Cases to Test

### Edge Case 1: Touch and Hold
- Touch edge but don't move
- Should start curl but with minimal effect
- Release should snap back

### Edge Case 2: Touch Outside Page
- Touch outside page bounds
- Should be ignored
- No curl effect

### Edge Case 3: Multi-Touch
- Touch with two fingers
- Should handle gracefully
- May ignore or use first touch

### Edge Case 4: Touch During Animation
- Start a page turn animation
- Try to touch during animation
- Should be ignored until animation completes

## Performance Tests

### Performance Test 1: Frame Rate
**Goal:** Verify 30+ FPS during curl

**Steps:**
1. Enable FPS counter (if available)
2. Perform various curl gestures
3. Observe frame rate

**Expected:**
- Minimum 30 FPS during curl
- Target 60 FPS on high-end devices
- No visible stuttering

### Performance Test 2: Responsiveness
**Goal:** Verify immediate response to touch

**Steps:**
1. Touch edge and immediately start dragging
2. Observe delay between touch and curl start

**Expected:**
- Curl should start immediately
- No perceptible delay
- Smooth tracking of finger movement

### Performance Test 3: Memory
**Goal:** Verify no memory leaks

**Steps:**
1. Perform 50+ page turns
2. Monitor memory usage
3. Check for memory growth

**Expected:**
- Memory usage should remain stable
- No continuous growth
- No crashes

## Debugging Tips

### If curl doesn't start:
1. Check that touch is within edge threshold (20% of width)
2. Verify PageCurlView is receiving touch events
3. Check logs for "Curl started" message
4. Ensure no animation is in progress

### If curl is jittery:
1. Check frame rate
2. Verify mesh resolution is appropriate
3. Check for excessive logging
4. Ensure touch events are being processed efficiently

### If page turn doesn't complete:
1. Verify drag distance exceeds 30% threshold
2. Check animation system is working
3. Look for errors in logs
4. Ensure onPageTurnComplete callback is set

### If snap back doesn't work:
1. Verify drag distance is below 30% threshold
2. Check animation system is working
3. Look for errors in logs
4. Ensure curl state is reset properly

## Logging

Enable verbose logging to see detailed touch handling:

```kotlin
// In TouchHandler.kt, all methods log with TAG = "TouchHandler"
// Look for these log messages:
// - "handleTouchDown: x=..., y=..."
// - "Curl started: FORWARD/BACKWARD"
// - "Touch ignored: not near edge"
// - "handleTouchMove: drag=..., radius=..."
// - "handleTouchUp: drag=..., threshold=..."
// - "Page turn triggered: FORWARD/BACKWARD"
// - "Snap back triggered"
```

Filter logs:
```bash
adb logcat | grep TouchHandler
```

## Success Criteria

All tests should pass with:
- ✅ Smooth curl animations
- ✅ Correct edge detection
- ✅ Accurate direction detection
- ✅ Proper threshold behavior
- ✅ No crashes or errors
- ✅ Good performance (30+ FPS)
- ✅ Responsive touch handling

## Known Limitations

1. **Page dimensions must be set**: TouchHandler requires page dimensions at construction
2. **Immutable dimensions**: If page size changes, create new TouchHandler instance
3. **Single touch only**: Multi-touch is not explicitly handled
4. **No touch pressure**: Touch pressure is not considered (could be added later)

## Next Steps After Testing

If all tests pass:
1. ✅ Mark Task 7 as complete
2. Move to Task 8: Integrate touch with curl rendering
3. Continue with Task 9: Fine-tune curl physics

If tests fail:
1. Document the failure
2. Check logs for errors
3. Review TouchHandler implementation
4. Fix issues and retest
