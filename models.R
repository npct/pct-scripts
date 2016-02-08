# # # # # # # # # # # # # # # # # # # #
# Estimating ECP from aggregate flows #
# # # # # # # # # # # # # # # # # # # #

logit_interact_formula <- clc_logit ~ dist_fast +
  I(dist_fast^2) +                     # sqr term
  I(dist_fast^0.5) +                   # sqrt term
  I(avslope - 0.003) +                 # avslope term
  I(dist_fast * (avslope - 0.003)) +   # dist/slope 'interact'
  I(dist_fast^2 * (avslope - 0.003)) + # 'interactsq' term
  I(dist_fast^0.5 * (avslope - 0.003)) # 'interactsqrt' term

# # The components of the above formula (for clarity)
# l$dist_fastsq <- l$dist_fast^2
# l$dist_fastsqrt <- l$dist_fast^0.5
# l$ned_avslope <- l$avslope - 0.003
# l$interact <- l$dist_fast * ned_avslope
# l$interactsq <- dist_fastsq * ned_avslope
# l$interactsqrt <- dist_fastsqrt * ned_avslope
# # Hardcoded model (verbose)
# logit_p <- -3.2941 + (-0.4659 * l$dist_fast) + (1.3430 * dist_fastsqrt) + (0.0062 * dist_fastsq) + (-31.9249 * ned_avslope) + (1.0989 * interact) + (-6.6162 * interactsqrt)

logit_p_local <- 

# mod_logsqr <- glm(clc ~ dist_fast + I(dist_fast^0.5) + avslope, data = flow, weights = All, family = "quasipoisson")

# # # # # # # #
# Diagnostics #
# # # # # # # #

# summary(mod_logsqr) # goodness of fit
#  
# cor(flow$clc, mod_logsqr$fitted.values)
 
#
# # Binning variables and validation
# brks <- c(0, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 9.5, 12.5, 15.5, 20.5, 1000)
# flow$binned_dist <- cut(flow$dist, breaks = brks, include.lowest = T)
# summary(flow$binned_dist) # summaries binned distances
#
# # Create aggregate variables
# gflow <- group_by(flow, binned_dist) %>%
#   summarise(dist = mean(dist), mbike = mean(clc),
#     total = sum(All.categories..Method.of.travel.to.work))
#
# lines(gflow$dist, gflow$clc, col = "green", lwd = 3)
#
# plot(gflow$dist, gflow$clc,
#   xlab = "Distance (miles)", ylab = "Percent cycling")

# # # # # # # # # # # # # # #
# Alternative models of plc #
# # # # # # # # # # # # # # #

# mod_logsqr_nofam <- glm(clc ~ dist + I(dist^0.5), data = flow, weights = All) # no link -> poor fit
# mod_logsqr_qbin <- glm(clc ~ dist + I(dist^0.5), data = flow, weights = All, family = "quasibinomial") # exactly same fit as quasipoisson
# mod_logsqr_qpois <- glm(clc ~ dist + I(dist^0.5), data = flow, weights = All, family = "quasipoisson")
# mod_loglin <- lm(log(gflow$mbike) ~ gflow$dist)
# mod_logsqr <- lm(log(gflow$mbike) ~ gflow$dist + I(gflow$dist^2))
# mod_logcub <- lm(log(gflow$mbike) ~ gflow$dist + I(gflow$dist^2) + I(gflow$dist^3))
# mod_logsqr <- glm(clc ~ dist + I(dist^0.5), data = flow, weights = All, family = "poisson")
# mod_logsqr <- glm(clc ~ dist + I(dist^0.5), data = flow, weights = All, family = "poisson")
# mod_logsqr_lin <- lm(log(clc) ~ dist + I(dist^0.5), data = gflow, weights = total)
# mod_logsqr_lin_all <- lm(log(clc) ~ dist + I(dist^0.5), data = flow, weights = All)
# summary(mod_logsqr_lin)
#
# plot(gflow$dist, gflow$mbike,
#   xlab = "Distance (miles)", ylab = "Percent cycling")
# lines(gflow$dist, exp(mod_loglin$fitted.values), col = "blue")
# lines(gflow$dist, exp(mod_logsqr$fitted.values), col = "red")
# lines(gflow$dist, exp(mod_logcub$fitted.values), col = "green")
