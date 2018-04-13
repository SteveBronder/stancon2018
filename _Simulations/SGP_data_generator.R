generate_GPP_data <- function(N) {
  # fixed values
  p <- 1
  X <- matrix(1, nrow = N, ncol = p)
  coords <- data.frame(lon = runif(N), lat = runif(N))
  D <- as.matrix(dist(coords))
  
  # parameter values
  eta <- .8
  eta_sq <- eta ^ 2
  sigma <- .3
  phi <- 7
  beta <- rep(2, p)
  C <- eta_sq * exp(-D * phi)
  w <- c(t(chol(C)) %*% rnorm(N))
  
  # response vector
  log_mu <- c(X %*% beta + w + rnorm(N, sd = sigma))
  y <- rpois(N, exp(log_mu))
  
  # data
  stan_data <- list(N = N,
                 y = y,
                 D = D,
                 p = p,
                 X = X)
}