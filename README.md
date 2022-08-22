## AR Notes
To get grid information, helpful to store the following pieces of content
    1. The sceneDepth.depthMap
    2. The capturedImage
    3. The sceneDepth.confidenceMap (if you want it)
    4. The cameraIntrinsicsInversed matrix
    5. The localToWorld matrix

Can just use sceneDepth and CVPixelBuffer. [Link here](https://developer.apple.com/videos/play/wwdc2020/10611/?time=1114%29,)

There are two developer samples available that utilize the sceneDepth api:
1. The Visualizing a Point Cloud Using Scene Depth sample that you have already found.
2. The Creating a Fog Effect Using Scene Depth sample