# directory information ----
setwd("D:/Projects/Stan/StanCon2018")
cmdstan_dir <- "D:/Projects/cmdstan-2.17.1"
gpustan_dir <- "D:/Projects/gpustan-2.17.1" 
output_dir <- "./_Simulations/_Output"

# cmdstan interface ----
source("./_Simulations/cmdstan_interface.R")

# data generation script ----
source("./_Simulations/GP_data_generator.R")

# clear previous results ----
#old_results <- list.files(
#  path = "./_Simulations/_Output/GP/",
#  pattern = "GP", full.names = T
#)
#for (fn in old_results) {
#  file.remove(fn)
#}

# globals ----
notes_cpu <- "Intel i7-6700, cmdstan-2.17.1"
notes_gpu <- "Intel i7-6700, NVIDIA GTX 1070, gpustan-2.17.1"
iterations <- 5

# dataset sizes ----
N_range <- c(16, 32, 64, 128, 256, 512)

# warmup ----
N_w <- 500

# samples ----
N_s <- 500

# seed generation ----
set.seed(0)
seeds <- sample.int(.Machine$integer.max, length(N_range) * iterations * 2)
seed_index <- 1

for (N in N_range) {
	for (i in 1:iterations) {
		# seeds ----
		data_seed <- seeds[seed_index]
		stan_seed <- seeds[seed_index + 1]
		seed_index <- seed_index + 2

		# generate data ----
		set.seed(data_seed)
		stan_data <- generate_GP_data(N)
		
		# simulate cpu ----
		# param string ----
		param_string <- get_cmdstan_param_string(
			num_samples = N_s,
			num_warmup = N_w,
			seed = stan_seed
		)

		# Stan hash experiment settings ----
		experiment_hash_cpu <- digest(list(stan_data, param_string, notes_cpu))
		experiment_hash_gpu <- digest(list(stan_data, param_string, notes_gpu))
		
		# data files ----
		fn_stan_cpu <- paste0(output_dir, "/GP/GP_", experiment_hash_cpu, ".rds")
		fn_stan_gpu <- paste0(output_dir, "/GP/GP_", experiment_hash_gpu, ".rds")

		# run sampling cpu ----
		res_stan <- get_samples(
			stan_file = normalizePath("./_Simulations/_Models/gp.stan", winslash = "/"),
			cmdstan_dir,
			normalizePath(paste0(output_dir, "/GP/_Temp"), winslash = "/"),
			stan_data,
			experiment_hash_cpu,
			param_string
		)

		# get parameters
		stan_fit <- data.frame(rho = mean(res_stan$samples$rho),
													 alpha = mean(res_stan$samples$alpha),
													 sigma = mean(res_stan$samples$sigma))
		
		saveRDS(
			list(
				time = res_stan$sampling_time,
				N = N,
				iteration = i,
				num_warmup = N_w,
				num_samples = N_s,
				GPU = FALSE,
				parameters_fit = stan_fit,
				notes = notes_cpu,
				y = stan_data$y,
				x = stan_data$x,
				x_predict = stan_data$x_predict,
				y_predict = colMeans(res_stan$samples[, -c(1:(10 + N))]),
				date = Sys.time()
			),
			file = fn_stan_cpu
		)
		
		# run sampling gpu ----
		res_stan <- get_samples(
			stan_file = normalizePath("./_Simulations/_Models/gp_gpu.stan", winslash = "/"),
			gpustan_dir,
			normalizePath(paste0(output_dir, "/GP/_Temp"), winslash = "/"),
			stan_data,
			experiment_hash_gpu,
			param_string
		)
		
		# get parameters
		stan_fit <- data.frame(rho = mean(res_stan$samples$rho),
													 alpha = mean(res_stan$samples$alpha),
													 sigma = mean(res_stan$samples$sigma))
		
		saveRDS(
			list(
				time = res_stan$sampling_time,
				N = N,
				iteration = i,
				num_warmup = N_w,
				num_samples = N_s,
				GPU = TRUE,
				parameters_fit = stan_fit,
				notes = notes_gpu,
				y = stan_data$y,
				x = stan_data$x,
				x_predict = stan_data$x_predict,
				y_predict = colMeans(res_stan$samples[, -c(1:(10 + N))]),
				date = Sys.time()
			),
			file = fn_stan_gpu
		)
	}
}