# Deploying HA Infrastructure

This project is part of Udacitys "Site Reliability Engineer".
The project demonstrates how to deploy high-available infrastructure to AWS using Terraform.  
First step in this project is to deploy the infrastructure that you can run Prometheus and Grafana on. 
Next we use the servers deployed to create an SLO/SLI dashboard. 
The code deploys a highly-available infrastructure to AWS in multiple zones using Terrafrom. 
Beside the monitoring stack deployed on AWS EKS, part of this is an RDS database cluster that has a replica in the alternate zone.

## Open Tasks

1. Enable VPC to have IPs in multiple availability zones
2. Configure replication of secondary database (RDS-S) from primary db 
3. Add a load balancer (ALB) along with VPC for zone 2
5. Tackle warning "Reference to undefined provider" on main.tf line 41, in module "vpc_west": (aws = aws.usw1)

## Guides & Readings

### Udacity Github Repository
- [Planning-for-High-Availability-and-Incident-Response](https://github.com/udacity/Planning-for-High-Availability-and-Incident-Response)

### AWS
- [AWS CLI Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [AWS CLI Configuration and credential file settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS CLI Environment variables to configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

### SRE
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/)
- [Building Secure and Reliable Systems - a book by Google](https://google.github.io/building-secure-and-reliable-systems/)
- [SLI/SLO article](https://thenewstack.io/sre-fundamentals-differences-between-sli-vs-slo-vs-sla/#:~:text=SLI%20(service-level%20indicators)%3A,and%20performing%20up%20to%20standard)
- [AWS DR strategies](https://aws.amazon.com/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/)
- [The Role of SREs in Observability](https://rootly.com/blog/the-role-of-sres-in-observability)
- [Benefits of Observability for Site Reliability Engineers](https://www.harrisonclarke.com/blog-2023/benefits-of-observability-for-site-reliability-engineers)

## Getting Started

Clone the appropriate git repo with the starter code. 
There will be 2 folders. Zone1 and zone2. 
This is where you will run the code from in your AWS Cloudshell terminal.

### Dependencies/Tools

- [helm](https://helm.sh/docs/intro/install/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Postman](https://www.postman.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)1
- [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/)

### Installation

#### 1.A. AWS setup 
**remote**

Open your AWS console and ensure it is set for region `us-east-1`. 
Open the CloudShell by clicking the little shell icon in the toolbar at the top near the search box. 

**locally**

Set up your aws credentials from Udacity AWS Gateway locally
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
- Set your region to `us-east-1` 

#### 1.B. AWS CLI Setup (did not get it working with udacity AWS credentials)
Based on [Set Up the AWS CLI](https://aws.amazon.com/de/getting-started/guides/setup-environment/module-three/)
proceed as follows:

1. Install the AWS CLI and verify with: `aws --version`
2. Create new profile with `aws configure --profile <profile_name>` and set:
    1. AWS Access Key ID
    2. AWS Secret Access Key
    3. Default Region (e.g. us-east-1)
    4. Default Output Format (i.e. json)
3. Get the available profiles with `aws configure list-profiles`
4. Switch the profile depending on your OS with:
    1. Linux and MacOS -> `export AWS_PROFILE=admin`
    2. Windows Command Prompt -> `setx AWS_PROFILE admin`
    3. PowerShell -> `$Env:AWS_PROFILE="admin"`
6. Get the currently used profile with `aws configure list`
7. Verify the currently active profile with `aws sts get-caller-identity`
8. Exemplary list S3 buckets from this profile with: `aws s3 ls --profile <profile_name>`
9. Remove unwanted profiles (or add manually), by editing the config files:
    1. `vi ~/.aws/credentials`
    2. `vi ~/.aws/config`

#### 2. Copy the AMI to your account

**Restore image**
```shell
    aws ec2 create-restore-image-task --object-key ami-0ec6fdfb365e5fc00.bin --bucket udacity-srend --name "udacity-<your_name>"
```

<!-- - Replace the owner field in `_data.tf` with your Amazon owner ID assigned on the AMI (you can get this in the console by going to EC2 - AMIs and selecting the Owned by me at the top filter) -->

**Copy the AMI to `us-east-2` and `us-west-1`**
```shell
aws ec2 copy-image --source-image-id <your-ami-id-from-above> --source-region us-east-1 --region us-east-2 --name "udacity-<your_name>"
aws ec2 copy-image --source-image-id <your-ami-id-from-above> --source-region us-east-1 --region us-west-1 --name "udacity-<your_name>"
```
- Make note of the ami output from the above 2 commands. You'll need to put this in the `ec2.tf` file for `zone1` for `us-east-2` and in `ec2.tf` file for `zone2` for `us-west-1` respectively
  
<!-- - Set your aws cli config to `us-east-2` -->

#### 3. Create S3 buckets for zone 1 (us-east-2) 
Close your CloudShell. Change your region to `us-east-2`. 
From the AWS console create an S3 bucket in `us-east-2`, e.g `s3-udacity-terraform-us-east-2`
- click next until created.
- Update `_config.tf` in the `zone1` folder with your S3 bucket name, e.g `s3-udacity-terraform-us-east-2` 
- **NOTE**: S3 bucket names MUST be globally unique!

#### 4. Create S3 buckets for zone 2 (us-west-1)
Change your region to `us-west-1`. 
From the AWS console create an S3 bucket in `us-west-1`, e.g `s3-udacity-terraform-us-west-1`
- click next until created.
- Update `_config.tf` in the `zone2` folder with your S3 bucket name, e.g `s3-udacity-terraform-us-west-1`
- **NOTE**: S3 bucket names MUST be globally unique!

#### 5. Create a private key pair for your EC2 instances
- Do this in **BOTH** `us-east-2` and `us-west-1`
- Name the key `udacity`

#### 6. Cloudshell setup (or local machine setup)
Setup your CloudShell. Open CloudShell in the `us-east-2` region. Install the following:
- helm
    - `export VERIFY_CHECKSUM=false`
    - `curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`

- terraform
    - `wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip`
    - `unzip terraform_1.0.7_linux_amd64.zip`
    - `mkdir ~/bin`
    - `mv terraform ~/bin`
    - `export TF_PLUGIN_CACHE_DIR="/tmp"`

- kubectl
    - `curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl`
    - `chmod +x ./kubectl`
    - `mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin`
    - `echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc`

#### 7. Deploy Terraform infrastructure
- Clone the starter code from the git repo to a folder CloudShell
- `cd` into the `zone1` folder
- `terraform init`
- `terraform apply` or `terraform apply -auto-approve`  

**NOTE** The first time you run `terraform apply` you may see errors about the Kubernetes namespace or an RDS error. 
Running it again AND performing the step below (No. 8) should clear up those errors.

#### 8. Setup Kubernetes config so you can ping the EKS cluster
- Delete `~/.kube/config` file locally, otherwise we will see 
  - `Tried to insert into contexts,which is a <class 'NoneType'> not a <class 'list'>`  
- Command `aws eks --region us-east-2 update-kubeconfig --name udacity-cluster`
- Get the <cluster_name> from command above, use it next
- Change kubernetes context to the new AWS cluster using the <cluster_name> from above via
  - `kubectl config use-context <cluster_name>`
  - e.g ` arn:aws:eks:us-east-2:139802095464:cluster/udacity-cluster`
- Confirm with: `kubectl get pods --all-namespaces`
- Then run `kubectl create namespace monitoring`

    <!-- - Change context to `udacity` namespace
         - `kubectl config set-context --current --namespace=udacity` -->
    
    <!-- 5. Once the script finishes **Configure nginx** 
    `sudo nano /etc/nginx/sites-enabled/default`
    
    ```
    server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1:8000;
        }
    }
    ``` -->
    
    <!-- 6. Then save.
    7. Be sure to check for errors, then reload nginx:
    ```
    sudo nginx -t
    sudo systemctl restart nginx
    ``` -->

#### 9. Config Prometheus with IP from Ubuntu-Web EC2 instance

**9.1. Copy the public IP address of your Ubuntu-Web EC2 instance.** 
- Login to the AWS console and copy the public IP address of your Ubuntu-Web EC2 instance. 
- Ensure you are in the us-east-2 region.

**9.2. Set public IP of your Ubuntu Web for Prometheus.**
- Edit the `prometheus-additional.yaml` file and replace the `<public_ip>` entries with the public IP of your Ubuntu Web. Save the file.

**Optional: Transfer `prometheus-additional.yaml` to Cloudshell via Git (in case you want to install Prometheus and Grafana from Cloudshell)**
- git commit (locally, after setting the IP in the previous step)
- git push origin master (updates the prometheus-additional.yaml file with actual IP)
- git pull (from cloudshell, in order to run commands from there with updated IP)

#### 10. Install Prometheus and Grafana (on EKS)
**Install via Helm**
- Change directories to your project directory `cd ../..` and run:
- `kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml --namespace monitoring`
- `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- `helm install prometheus prometheus-community/kube-prometheus-stack -f "values.yaml" --namespace monitoring`
  - if helm install above doenst work out, try helm install without values.yaml below
  - `helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring`

#### 11. Access Prometheus and Grafana
**Via Port forwarding**
- `kubectl -n monitoring  port-forward svc/prometheus-grafana  8888:80`
- `kubectl -n monitoring  port-forward svc/prometheus-kube-prometheus-prometheus 8889:9090`
- Point your local web browser to http://localhost:8888 for Grafana access and http://localhost:8889 for Prometheus access -->

**Via Load Balancer**
- Get the DNS of your load balancer provisioned to access Grafana. 
- You can find this by opening your AWS console and going to EC2 -> Load Balancers and selecting the load balancer provisioned. 
- The DNS name of it will be listed below that you can copy and paste into your browser. 
- Type that into your web browser to access Grafana.

**Login**
- Login to Grafana with `admin` for the username and `prom-operator` for the password.

#### 12. Postman 
- Install Postman from [here](https://www.postman.com/downloads/). 
- See additional instructions for [importing the collection, and enviroment files](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#importing-postman-data)

#### 13. Setup Postman (for interacting with web api) 
Open Postman and load the files `SRE-Project-postman-collection.json` and `SRE-Project.postman_environment.json`

1. At the top level of the project in Postman, create the `public-ip`, `email` and `token` variable in the Postman file with the public IP you gathered from above and click Save. You can choose whatever you like for the email and see the next step for the token.

2. Run the `Initialize the Database` and `Register a User` tasks in Postman by clicking the "Send" button on top. In the register tasks, you will output a token. Use this token to create a token variable (under "Auth").

3. Run `Create Event` for 100 iterations by clicking the top level `SRE Project` folder in the left-hand side and select just `Create Event` and click the Run icon in the toolbar.

4. Run `Get all events` for 100 iterations by clicking the top level `SRE Project` folder in the left-hand side and select just `Get All Events` and click the Run icon in the toolbar.

5. Optional: Run the Postman runners to generate some traffic. Use 100 iterations


## Project Instructions

1. Create an SLO/SLI document such as the template [here](slo_sli_template.md). You will fill in the **SLI** column with a description of what the combination category and SLO represent. You'll implement these 4 categories in 4 panels in Grafana using Prometheus queries later on. This is a good tool for creating tables in Markdown https://tableconvert.com. I recommend using that tool for MD tables since they can get hard to read in a pure text editor.

2. Create a document that details the infrastructure. This is an exercise to identity assets for failover. You will also define basic DR steps for your infrastructure. Your orgnization has provided you a [requirement document](requirements.md) for the infrastructure. Please see [this document](dr_template.md) for a template to use.

3. Open Grafana in your web browser
    1. Create a new dashboard with 4 panels. The Prometheus datasource should already be added that you can pull data from. The Flask exporter exports metrics for your EC2 instances provisioned during the install. Please note, while making the panel display the information in a way that makes sense (percentage, milliseconds, etc.) is also good, it is not necessarily a requirement. The backend query and data representation is more important. Same goes for colors and type of graph displayed.
    2. Create the 4 SLO/SLI panels as defined in the SLO/SLI document. The 4 panel categories will be availability (availability), remaining error budget (error budget), successful requests per second (throughput), and 90th percentile requests finish in this time (latency). See the following for more information on potential metrics to use https://github.com/rycus86/prometheus_flask_exporter
        - **NOTE**: You will not see the goal SLO numbers in your dashboard and that is fine. The application doesn't have enough traffic or time to generate a 99% availabiliy or have an error budget that works.
    3. Please submit your Prometheus queries you use for you dashboards in the `prometheus_queries.md` file [linked here](prometheus_queries.md).
    4. Please take a screenshot of your created dashboard and include that as part of your submission for the project.

4. Deploy the infrastructure to zone1
    1. You will need to make sure the infrastructure is highly available. Please see the `requirements.md` document [here](requirements.md) for details on the requirements for making the infrastructure HA. You will modify your code to meet those requirements.
        **Note for availability zones** that not all regions have the same number of availability zones. You will need to lookup the AZs for `us-east-2`. You will get errors when first running the code you will have to fix!
        - For the application load balancer, please note the technical requirements:
            - This will attach to the Ubuntu VMs on port 80.
            - It should listen on port 80
        <!-- - You will need to set the following for the RDS instances
            - Create 2 instances nodes for each cluster
            - Set the backup retention window to 5 days -->
    2. Make the appropriate changes to your code
        - `cd` into your `zone1` folder
        - `terraform init`
        - `terraform apply`
    3. Please take a screenshot of a successful Terraform run and include that as part of your submission for the project.

5. Deploy the infrastructure to zone2 (DR)
    1. You will need to make sure the infrastructure is highly available. Please see the `requirements.md` document [here](requirements.md) for details on the requirements for making the infrastructure HA. You will modify your code to meet those requirements.
        <!-- - Each VM has 3 instances (EC2)
        - Each Kubernetes cluster has 2 nodes -->
        <!-- - The VPC has IPs in multiple availability zones.  -->
        **Note for availability zones** that not all regions have the same number of availability zones. You will need to lookup the AZs for `us-west-1`. You will get errors when first running the code you will have to fix in the `zone1` `main.tf` file
        - You will need to update the bucket name in the `_data.tf` file under the `zone2` folder to reflect the name of the bucket you provisioned in `us-east-2` earlier
        - For the application load balancer, please note the technical requirements:
            - This will attach to the Ubuntu VMs on port 80.
            - It should listen on port 80
            - **HINT**: we actually provisioned the VPC for us-west-1 in the `zone1` folder, so you'll need to reference the subnet and vpc ID from that module output. Here is the code block you'll need to utilize for the ALB:
            ```
            subnet_id = data.terraform_remote_state.vpc.outputs.public_subnet_ids
            vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
            ```
    2. Make the appropriate changes to your code
    - `cd` into your `zone2` folder
    - `terraform init`
    - `terraform apply`
    3. Please take a screenshot of a successful Terraform run and include that as part of your submission for the project.

6. Implement basic SQL replication and establish backups
    **NOTE:** The RDS configuration is completed under the `zone1` folder. Due to the way it was implemented in Terraform BOTH region RDS instances are completed under the same Terraform project.
    1. You will need to make sure the cluster is highly available. Please see the `requirements.md` document [here](requirements.md) for details on the requirements for making the cluster HA. You will modify your code to meet those requirements. Additionally, you will need to set the following for the RDS instnaces:
        <!-- - Create 2 instance nodes for each cluster (primary and secondary clusters)
        - Set the backup retention window to 5 days -->
        - Setup the source name and region for your RDS instance in your secondary zone
        - You will need to add multiple availability zones for the RDS module. The starter code only contains 1 zone for each RDS instance in each region.
    2. The code for the `rds-s` cluster is commented out in the `rds.tf` file under the `zone-1` folder. You will need to fix the `rds-s` module and then uncomment this code for it to work
    3. Please take a screenshot of a successful Terraform run and include that as part of your submission for the project.

7. Destroy it all. 
    1. Delete the RDS Clusters manually: first the primary, then the secondary. 
    2. Destroy zone2 first, then zone1 using `terraform destroy`.
    3. Please take a screenshot of the final output from Terraform showing the destroyed resources and include that as part of your submission for the project.


## Standout Suggestions
If you want to take your project even further going above and beyond, here are 3 standout suggestions:

1. Perform a failover of their application load balancer to their secondary region using route 53 DNS
2. Fail over the RDS instance to the secondary region so it becomes the primary target and the first region becomes the replica
3. Create an additional AWS module to provision another piece of infrastructure not discussed in the project

## License
[License](../LICENSE.md)
