# BeeSwarm

### Model
Run instructions
1. `cd model`
2. If you want to run natively using your GPU natively go to step 3, otherwise skip to step 4 to run in Docker.
3. Run `run_model_mac.sh`, `run_model_*` depending on your operating system.
4. To run it in Docker you can run `docker compose up --build`

### Load balancer
Run instructions
1. `cd lb`
2. If you want to run locally for testing, skip to step 4, otherwise continue with step 3
3. `docker compose up --build`
4. If you want to test the frontend run `cd ui` and `npm run dev` or for the api `cd api` and `npm start`
