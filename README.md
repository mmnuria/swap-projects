# High-Performance Web Servers – Projects and Practices

This repository contains all the projects and practical assignments completed for the course **High-Performance Web Servers**. The final grade obtained was a **10** (with highest honors).

## General Objective

The main goal of the assignments is to create a **web farm** using Docker containers, orchestrated with load balancers, firewalls, SSL certificates, and to evaluate the infrastructure's performance using various benchmarking tools.

---

## Technologies and Tools Used

- Docker for container creation and orchestration  
- Load balancer configuration with enabled statistics  
- Creation and management of self-signed SSL certificates for servers and load balancers  
- Firewall configuration and customization
- Apache Benchmark for basic load testing  
- Locust for traffic simulation and performance testing in multi-container scenarios  

---

## Contents and Tasks Performed

1. **Evaluating the performance** of the web infrastructure using Docker containers and applying different load tests.   
2. Creating Docker images for web servers and load balancers.  
3. Managing server replicas, data volumes, and Docker networking.  
4. Configuring load balancers with statistics enabled.  
5. Creating and configuring self-signed SSL certificates to secure communication.  
6. Setting up firewalls with custom rules to protect the infrastructure.  
7. Configuring and using **Apache Benchmark** to run basic load tests on the web farm.  
8. Implementing **Locust** in a multi-container environment to simulate user traffic and assess system performance under load.  
9. Analyzing and comparing results to determine the effectiveness of previously implemented security and performance configurations. 
---

## How to Use This Repository

To reproduce or study the practices, it is recommended to:

1. Have Docker and Docker Compose installed.  
2. Review each folder or individual practice to understand the steps and configurations performed.  
3. Execute load tests using Apache Benchmark or Locust as described in each practice.  

---

## Note

These assignments are academic exercises aimed at understanding and applying advanced concepts in high-performance web servers and container orchestration.

