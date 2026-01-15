# Infrastructure

## AWS Zones
HA is achieved with deployments in two aws regions, namely: 
* us-east-2 (primary)
* us-west-1 (DR)

In addition, the VPC has IPs in multiple availability zones, for the VMs and for the database.

## Servers and Clusters

### Table 1.1 Summary
| Asset        | Purpose                                           | Size                                  | Qty                      | DR                                                                                                           |
|--------------|---------------------------------------------------|---------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------|
| Asset name   | Brief description                                 | AWS size eg. t3.micro (if applicable) | Number of nodes/replicas | Identify if this asset is deployed to DR, replicated, created in multiple locations or just stored elsewhere |
|--------------|---------------------------------------------------|---------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------|
| VM           | web app with API                                  | t3.micro                              | 3 instances (EC2)        | Deployed to 2 regions with 2 availability zones each (access via load balancer)                              |
| Load Balancer| ALB balances the load between web app VMs         |                                       | 2                        | Application load balancer in each region                                                                     |  
| EKS          | Kubernetes cluster with monitoring stack          | 2 nodes                               | 2                        | Deployed to 2 regions with 2 availability zones each                                                         |
| RDS cluster  | Database with 2 instance nodes for each cluster   | db.t2.small                           | 2 (primary and secondary)| Replicated from zone1 to zone2                                                                               | 
| EC2 keys     | Access EC2 instances                              |                                       | 2 (one for each region)  |                                                                                                              |
|--------------|---------------------------------------------------|---------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------|

### Descriptions
More detailed descriptions of each asset identified above.

## DR Plan
### Pre-Steps:
Steps we would perform to setup the infrastructure in the other region. Its not super detailed, but high-level should suffice.

````
Ensure the infrastructure is set up and working in the DR site.
Ensure both sites are configured the same
````

## Steps:
We won't actually perform these steps, but describe what we would do to "fail-over" our application and database cluster to the other region. 
We cover all the pieces that were setup and how we use those in the other region

````
- Create a cloud load balancer and point DNS to the load balancer. 
- This way you can have multiple instances behind 1 IP in a region. During a failover scenario, you would fail over the single DNS entry at your DNS provider to point to the DR site. 
- This is much more intelligent than pointing to a single instance of a web server.
- Have a replicated database and perform a failover on the database. 
- While a backup is good and necessary, it is time-consuming to restore from backup. In this DR step, you would have already configured replication and would perform the database failover. 
- Ideally, your application would be using a generic CNAME DNS record and would just connect to the DR instance of the database.
````

````
- Point your DNS to your secondary region
- This can be done with a name provider like Amazon route 53
- Failover your database replication instances to another region
- Manually force the secondary region to become primary at the database level, or
- Automatically failover the database by health checks
````
