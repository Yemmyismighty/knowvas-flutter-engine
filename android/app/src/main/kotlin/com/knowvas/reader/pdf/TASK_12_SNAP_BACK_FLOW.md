# Snap-Back Animation Flow Diagram

## Visual Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SNAP-BACK ANIMATION FLOW                      │
└─────────────────────────────────────────────────────────────────┘

Step 1: User touches near edge
┌──────────────────┐
│   User Touch     │
│   Near Edge      │
│   (x=850, y=750) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  TouchHandler    │
│  handleTouchDown │
│  → CurlStarted   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  PageCurlView    │
│  isCurling=true  │
│  onCurlStarted() │
└──────────────────┘


Step 2: User drags (but < 30%)
┌──────────────────┐
│   User Drags     │
│   Distance: 200px│
│   (< 30% = 300px)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  TouchHandler    │
│  handleTouchMove │
│  → CurlUpdated   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  PageCurlView    │
│  Update curl     │
│  Render frame    │
└──────────────────┘


Step 3: User releases touch
┌──────────────────┐
│  User Releases   │
│  Touch           │
│  (ACTION_UP)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────┐
│  TouchHandler.handleTouchUp  │
│                              │
│  dragDistance = 200px        │
│  threshold = 300px (30%)     │
│                              │
│  if (200 > 300) → NO         │
│  → SnapBackTriggered         │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  PageCurlView                │
│  handleTouchResult()         │
│                              │
│  case SnapBackTriggered:     │
│    → startSnapBackAnimation()│
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  AnimationController         │
│  startSnapBackAnimation()    │
│                              │
│  • duration = 250ms          │
│  • easing = elasticEaseOut   │
│  • target = FLAT             │
│  • start animation loop      │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Animation Loop (60 FPS)     │
│                              │
│  Frame 1 (t=0.00): radius=200│
│  Frame 2 (t=0.06): radius=180│
│  Frame 3 (t=0.13): radius=150│
│  Frame 4 (t=0.19): radius=110│
│  Frame 5 (t=0.25): radius=70 │
│  Frame 6 (t=0.31): radius=35 │
│  Frame 7 (t=0.38): radius=10 │
│  Frame 8 (t=0.44): radius=5  │
│  Frame 9 (t=0.50): radius=8  │ ← Bounce!
│  Frame 10(t=0.56): radius=3  │
│  Frame 11(t=0.63): radius=1  │
│  Frame 12(t=0.69): radius=2  │ ← Small bounce
│  Frame 13(t=0.75): radius=0  │
│  Frame 14(t=0.81): radius=0  │
│  Frame 15(t=1.00): radius=0  │ ← Complete
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  onUpdate Callback           │
│  (called each frame)         │
│                              │
│  • Queue GL update           │
│  • curlRenderer.updateCurl() │
│  • requestRender()           │
└──────────────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  onComplete Callback         │
│  (called once at end)        │
│                              │
│  • curlRenderer.resetCurl()  │
│  • currentCurlParams = FLAT  │
│  • isCurling = false         │
└──────────────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Final State                 │
│                              │
│  • Page is flat              │
│  • Curl radius = 0           │
│  • Ready for next interaction│
└──────────────────────────────┘
```

## Elastic Easing Visualization

The elastic easing creates a bounce effect:

```
Curl Radius Over Time (Elastic Easing)

200 │ ●
    │  ╲
180 │   ╲
    │    ╲
160 │     ╲
    │      ╲
140 │       ╲
    │        ╲
120 │         ╲
    │          ╲
100 │           ╲
    │            ╲
 80 │             ╲
    │              ╲
 60 │               ╲
    │                ╲
 40 │                 ╲
    │                  ╲
 20 │                   ╲___
    │                       ╲╱╲_
  0 │________________________╲__●
    └─────────────────────────────
    0ms   50ms  100ms 150ms 200ms 250ms
    
    Note: The "bounce" at the end is the elastic effect
```

## Input Blocking During Animation

```
┌─────────────────────────────────────────────────────────────┐
│                    INPUT BLOCKING                            │
└─────────────────────────────────────────────────────────────┘

Timeline:
0ms                                                      250ms
│                                                           │
├───────────────────────────────────────────────────────────┤
│         SNAP-BACK ANIMATION IN PROGRESS                   │
│         animationController.isAnimating() = true          │
│                                                           │
│  ❌ Touch events are BLOCKED                             │
│  ❌ onTouchEvent() returns true immediately              │
│  ❌ No new curl interactions can start                   │
│                                                           │
├───────────────────────────────────────────────────────────┤
                                                            │
                                                            ▼
                                                    Animation Complete
                                                    isAnimating() = false
                                                    ✅ Touch events allowed
```

## State Transitions

```
┌─────────────────────────────────────────────────────────────┐
│                    STATE MACHINE                             │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────┐
                    │   FLAT   │
                    │ (Initial)│
                    └────┬─────┘
                         │
                         │ Touch near edge
                         ▼
                    ┌──────────┐
                    │ CURLING  │
                    │(Dragging)│
                    └────┬─────┘
                         │
                         │ Release touch
                         │ (drag < 30%)
                         ▼
                    ┌──────────┐
                    │SNAP-BACK │
                    │(Animating)│
                    └────┬─────┘
                         │
                         │ Animation complete
                         ▼
                    ┌──────────┐
                    │   FLAT   │
                    │  (Reset) │
                    └──────────┘
```

## Component Interaction

```
┌─────────────────────────────────────────────────────────────┐
│              COMPONENT INTERACTION DIAGRAM                   │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│ TouchHandler │
│              │
│ • Detects    │
│   drag < 30% │
│ • Returns    │
│   SnapBack   │
│   Triggered  │
└──────┬───────┘
       │
       │ TouchResult.SnapBackTriggered
       │
       ▼
┌──────────────┐
│PageCurlView  │
│              │
│ • Receives   │
│   result     │
│ • Starts     │
│   animation  │
│ • Blocks     │
│   input      │
└──────┬───────┘
       │
       │ startSnapBackAnimation()
       │
       ▼
┌──────────────────┐
│AnimationController│
│                  │
│ • Manages timing │
│ • Elastic easing │
│ • 250ms duration │
│ • Interpolates   │
│   params         │
└──────┬───────────┘
       │
       │ onUpdate (each frame)
       │
       ▼
┌──────────────┐
│PageCurlView  │
│              │
│ • Queue GL   │
│   update     │
│ • Request    │
│   render     │
└──────┬───────┘
       │
       │ updateCurl()
       │
       ▼
┌──────────────┐
│CurlRenderer  │
│              │
│ • Update     │
│   mesh       │
│ • Render     │
│   frame      │
└──────────────┘
       │
       │ onComplete
       │
       ▼
┌──────────────┐
│PageCurlView  │
│              │
│ • Reset curl │
│ • Reset state│
│ • Unblock    │
│   input      │
└──────────────┘
```

## Key Implementation Details

### 1. Threshold Detection
```kotlin
// TouchHandler.kt
val threshold = pageWidth * PAGE_TURN_THRESHOLD  // 0.3 = 30%

if (dragDistance > threshold && direction != null) {
    return TouchResult.PageTurnTriggered(direction)
} else {
    return TouchResult.SnapBackTriggered  // ← Snap-back!
}
```

### 2. Elastic Easing
```kotlin
// AnimationController.kt
private fun elasticEaseOut(t: Float): Float {
    if (t == 0f || t == 1f) return t
    
    val p = 0.3f  // Period
    val s = p / 4f  // Shift
    
    // Exponential decay with sine wave = bounce!
    return (2f.pow(-10f * t) * sin((t - s) * (2f * PI) / p) + 1f)
}
```

### 3. Input Blocking
```kotlin
// PageCurlView.kt
override fun onTouchEvent(event: MotionEvent): Boolean {
    // Block all input during animation
    if (animationController.isAnimating()) {
        return true  // Consume event, don't process
    }
    // ... normal touch handling
}
```

### 4. State Reset
```kotlin
// PageCurlView.kt - onComplete callback
onComplete = {
    // Reset renderer
    queueEvent {
        curlRenderer.resetCurl()
        requestRender()
    }
    
    // Reset local state
    currentCurlParams = CurlParameters.FLAT
    isCurling = false
}
```

## Performance Characteristics

- **Frame Rate**: 60 FPS (16ms per frame)
- **Animation Duration**: 250ms (15 frames)
- **Memory**: Zero allocations during animation
- **Thread Safety**: GL updates on render thread
- **CPU Usage**: Minimal (simple interpolation math)

## User Experience

The snap-back animation provides:

1. **Visual Feedback**: User sees the page "bounce back"
2. **Natural Feel**: Elastic easing mimics real paper
3. **Clear Intent**: Indicates drag was insufficient
4. **Smooth Motion**: 60 FPS ensures fluid animation
5. **Responsive**: 250ms is fast enough to feel immediate

## Conclusion

The snap-back animation is a critical part of the page curl UX. It provides clear feedback when a drag gesture doesn't meet the threshold for a page turn, while maintaining the natural, physical feel of turning real pages.
