# Gesture
## React SDK

Installation:
`npm i gesture-react-sdk`

You can choose to only use one of the two hands. Shape is either "open", "closed", or "unknown" (low confidence)

```jsx
export default function Example() {
  const { pose, ready } = useGestureWS()
  return (
    <div>
      <main>
        <h1>Gesture - SDK Demo</h1>
        <p>Ready: {ready}</p>
        {ready && <><div>
          <h3>Left</h3>
          <p>x: {pose.left.x}, y: {pose.left.y}, z: {pose.left.z}, shape: {pose.left.shape}</p>
        </div>
        <div>
          <h3>Right</h3>
          <p>x: {pose.right.x}, y: {pose.right.y}, z: {pose.right.z}, shape: {pose.right.shape}</p>
        </div></>}
      </main>
    </div>
  )
}
```
