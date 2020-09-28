data {
  
  int<lower=1> N;                          //  Number of obs. (polls) 
  int<lower=1> SY;                         //  Number of elections (state crossed election year)
  int<lower=1> RG;                         //  Number of regions 

  real<lower=0, upper=1> poll[N];          //  two-party poll share
  real<lower=0, upper=1> vote[SY];         //  two -party vote share
  
  vector[SY] gender_rep;                      // race Rep. dummy (1 = non white)
  vector[SY] gender_dem;                      // race Dem. dummy (1 = non white)

  vector<lower=1>[N] sample_size;          //  poll sample size
  
  int<lower=1, upper=SY> sy_id[N];         //  identifies election (state - year)
  int<lower=1, upper=RG> rg_id[N];         //  identifies region 
} 

transformed data {
  vector[SY] logit_vote;
  for (i in 1:SY){
    logit_vote[i] = logit(vote[i]);
  }
}

parameters {
  
  // Hyper-parameters

    // Mean model

    real mu_alpha;
    real<lower=0> sig_alpha;
    
    real mu_beta1;
    real<lower=0> sig_beta1;
    
    real mu_beta2;
    real<lower=0> sig_beta2;

    
    // Variance model

    real mu_tau;
    real<lower=0> sig_tau;

  // Scaled Parameters
    
    // Mean model

    vector[SY] alpha_sc;
    vector[RG] beta1_sc;
    vector[RG] beta2_sc;

    // Variance model
    
    vector[SY] tau_sc;
    
} 

transformed parameters {
  
  // Mean model
  
    // Parameters
    
    vector[SY] alpha;                         
    vector[RG] beta1;
    vector[RG] beta2;

    vector[SY] tau; 

  // Mean model
  
    alpha = mu_alpha + sig_alpha * alpha_sc;
    beta1 = mu_beta1 + sig_beta1 * beta1_sc;
    beta2 = mu_beta2 + sig_beta2 * beta2_sc;

  // Variance model
  
    tau = mu_tau + sig_tau * tau_sc;
    
}

model {
  
  vector[N] logit_p;
  vector[N] p;
  vector[N] log_sigma;
  vector[N] sigma;
  
  // Mean model
  
    // Hyper priors
    
    mu_alpha ~ normal(0,0.2);
    sig_alpha ~ normal(0,0.2) T[0,]; // half normal due to bounds
    
    mu_beta1 ~ normal(0,0.2);
    sig_beta1 ~ normal(0,0.2) T[0,]; // half normal due to bounds
    
    mu_beta2 ~ normal(0,0.2);
    sig_beta2 ~ normal(0,0.2) T[0,]; // half normal due to bounds
    
    // Priors
    
    alpha_sc ~ normal(0,1);
    beta1_sc ~ normal(0,1);
    beta2_sc ~ normal(0,1);

  // Vairiance model
  
    // Hyper priors
    
    mu_tau ~ normal(0,0.05);
    sig_tau ~ normal(0,0.05) T[0,]; // half normal due to bounds

    // Priors
    
    tau_sc ~ normal(0,1);

  // Model for Polling Data
  
  for(i in 1:N){
    logit_p[i] = logit_vote[sy_id[i]] + 
                  alpha[sy_id[i]] + 
                  beta1[rg_id[i]] * gender_rep[sy_id[i]] +
                  beta2[rg_id[i]] * gender_dem[sy_id[i]] ;
    p[i] = inv_logit(logit_p[i]);
    log_sigma[i] = log(p[i]*(1-p[i])/sample_size[i]) + 
                    tau[sy_id[i]] ;
    sigma[i] = exp(log_sigma[i]);
    poll[i] ~ normal(p[i],sqrt(sigma[i]));
  }
  
}