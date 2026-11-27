# maxshefter-lab.online

Personal portfolio site of **Maxim Shefter**, DevOps & Cloud Engineer.  
The site itself is simple. The interesting part is how it's built and shipped: **100% Terraform, deployed by GitHub Actions over OIDC, with no stored AWS keys.**

## Architecture

```
git push main
  └─ GitHub Actions ──OIDC──▶ IAM role (main branch of this repo only)
        ├─ aws s3 sync site/ ─▶ S3 (private, versioned, encrypted)
        └─ CloudFront invalidation

visitor ─▶ Route 53 ─▶ CloudFront (ACM TLS, HTTP/3, security headers, www→apex 301)
                          └─ S3 origin via Origin Access Control
```

| Component | Why |
|---|---|
| S3 + OAC | Bucket stays fully private. Only this CloudFront distribution can read it |
| CloudFront | HTTPS, global caching, managed security headers, custom 404 |
| CloudFront Function | 301 redirect from `www.` to the apex domain |
| ACM | Free TLS certificate, DNS-validated through Route 53 |
| Route 53 | DNS, with A/AAAA alias records for apex + www |
| IAM OIDC role | Least privilege: sync one bucket and invalidate one distribution |

## Repo layout

```
site/                       static site (index.html, 404.html, photo.jpg, og.png, robots.txt, sitemap.xml)
terraform/                  all infrastructure
.github/workflows/
  deploy.yml                site/** changes → S3 + invalidation + smoke test
  terraform-ci.yml          fmt / validate / tflint on every Terraform change
```

## First-time setup

**Prerequisites:** AWS CLI configured locally, and Terraform >= 1.6.

**1. Create the hosted zone first**

```bash
cd terraform
terraform init
terraform apply -target=aws_route53_zone.main
terraform output name_servers
```

**2. Delegate the domain to Route 53.** In Namecheap, go to Domain List → `maxshefter-lab.online` → Manage → Nameservers → **Custom DNS**, then paste the 4 name servers. Propagation usually takes 5–30 minutes. Check it with:

```bash
dig NS maxshefter-lab.online +short
```

**3. Apply everything else.** ACM validation waits until DNS resolves through Route 53.

```bash
terraform apply
```

> If the GitHub OIDC provider already exists in your account, run with `-var create_github_oidc_provider=false`.

**4. Configure GitHub.** In the repo, go to Settings → Secrets and variables → Actions → **Variables** and add:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | `terraform output -raw github_deploy_role_arn` |
| `S3_BUCKET` | `terraform output -raw bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `terraform output -raw cloudfront_distribution_id` |
| `CONTACT_EMAIL` | the email shown on the site (it stays out of the repo) |

Also create an environment named `production` under Settings → Environments.

The deploy job also stamps the commit SHA and build time into the footer.

**5. Deploy.** Push to `main`, or run **Deploy site** manually from the Actions tab.

## Cost

| Item | Cost |
|---|---|
| Route 53 hosted zone | ~$0.50 / month |
| S3, CloudFront | Free Tier for a personal site |
| ACM, CloudFront Functions | free |
| **Total** | **≈ $0.50–1 / month** |

## Teardown

```bash
aws s3 rm s3://maxshefter-lab.online --recursive
cd terraform && terraform destroy
```

The bucket is versioned, so empty old versions too, or temporarily add `force_destroy = true`.
