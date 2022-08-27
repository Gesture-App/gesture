import useGestureWS from 'gesture-react-sdk'
import _ from './App.css'

export default function Home() {
  const { pose, ready } = useGestureWS()
  return (
    <div className="container">
      <main className="main">
        <h1>Gesture - SDK Demo</h1>
        <p>Ready: {ready ? 'yes' : 'no'}</p>
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
