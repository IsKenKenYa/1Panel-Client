class MockAIResponses {
  static Map<String, dynamic> ollamaModels() => {
    "data": [
      {"name": "llama2", "size": 3826793677},
      {"name": "mistral", "size": 4109865189}
    ]
  };

  static Map<String, dynamic> mcpServers() => {
    "data": [
      {"name": "server1", "status": "running"},
      {"name": "server2", "status": "stopped"}
    ]
  };
}

class MockContainerResponses {
  static Map<String, dynamic> containerList() => {
    "data": [
      {"id": "c1", "name": "container1", "state": "running"},
      {"id": "c2", "name": "container2", "state": "exited"}
    ]
  };

  static Map<String, dynamic> imageList() => {
    "data": [
      {"id": "i1", "tags": ["image1:latest"]},
      {"id": "i2", "tags": ["image2:latest"]}
    ]
  };

  static Map<String, dynamic> networkList() => {
    "data": [
      {"id": "n1", "name": "bridge", "driver": "bridge"},
      {"id": "n2", "name": "host", "driver": "host"}
    ]
  };

  static Map<String, dynamic> volumeList() => {
    "data": [
      {"name": "vol1", "driver": "local"},
      {"name": "vol2", "driver": "local"}
    ]
  };
}
