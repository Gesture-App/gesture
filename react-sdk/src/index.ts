import { useEffect, useState } from 'react'
import useWebSocket, { ReadyState } from 'react-use-websocket'

interface Vec3 {
  x: number,
  y: number,
  z: number,
  shape: string,
}

const DefaultVec3: Vec3 = {
  x: 0,
  y: 0,
  z: 0,
  shape: 'open'
}

interface InputJSON {
  left: Vec3,
  right: Vec3,
}

const useGestureWS = (socketURL: 'ws://localhost:8888') => {
  const { lastMessage, readyState } = useWebSocket(socketURL);
  const [state, setState] = useState<InputJSON>({
    left: DefaultVec3,
    right: DefaultVec3,
  })

  useEffect(() => {
    try {
      const obj = JSON.parse(lastMessage?.data || "") as InputJSON
      setState(obj)
    } catch (_) {
    }
  }, [lastMessage])

  return { pose: state, ready: readyState !== ReadyState.OPEN }
}

export default useGestureWS
