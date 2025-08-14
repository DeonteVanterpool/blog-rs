This is the code for running by personal blog / portfolio website [deontevanterpool.com](deontevanterpool.com). Templates, assets, blog posts, and portfolio entries are served from S3 containers. Environment variables must be passed using docker. Example .env file:
```bash
BLOG_POSTS_BUCKET=<blog post bucket>
PORTFOLIO_ENTRIES_BUCKET=<portfolio entries bucket>
TEMPLATES_BUCKET=<templates bucket>
AWS_REGION=<region>
AWS_ACCESS_KEY_ID=<access key id>
AWS_SECRET_ACCESS_KEY=<access key>
```

To run, use the command `docker-compose up` (or similar). 
Remember to configure the Caddyfile correctly to point to your own website.

Blog posts are written using markdown and YAML frontmatter for metadata.
