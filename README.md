# Clogs
A lightweight toolset to provide visibility into container/stack logs, and their health status.
An alternative to traditional status pages, with deeper insights into your container logs.

Clogs is a stack of tools, consisting of:
- [Clogs Agent](https://github.com/kiliansen/clogsagent/) - A lightweight service that sources logs/metrics from your containers, and ships them to the Clogs Backend for processing and visualization.
- [Clogs Server](https://github.com/kiliansen/clogsserver) - A backend service that receives logs/metrics from the Clogs Agent, processes them, and provides an API for the Clogs Frontend.
- [Clogs Frontend](https://github.com/kiliansen/clogsweb) - A web-based dashboard that visualizes the logs/metrics received from the Clogs Backend.

# Deploy (Simple)
To quickly deploy Clogs use the fully integrated Docker Image:
```bash
docker run -d -p 5173:5173 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock:ro ghcr.io/kiliansen/clogs:latest
```

Web UI will be available at `http://localhost:5173`.
Agents can be configured to point to the server at `http://<host-ip>:8000`.

## Licensing

When using Clogs, please be aware of the following licensing options:

- [LICENSE](LICENSE) - AGPL-3.0 (community edition)
- [Commercial](LICENSE-COMMERCIAL.md) - Enterprise/SaaS licensing
- [CLA](CLA.md) - Required for contributions

For just most use-cases, the AGPL-3.0 community edition will be sufficient. 
However, if you require a commercial license without AGPL obligations, please create an Issue in the respective repository to get in contact for commercial licensing options.