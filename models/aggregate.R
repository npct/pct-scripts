# # # # # # # # # # # # # # # # # # # #
# Estimating ECP from aggregate flows #
# # # # # # # # # # # # # # # # # # # #

mod_logsqr <- glm(clc ~ dist_fast + I(dist_fast^0.5), data = flow, weights = All, family = "quasipoisson")

# # # # # # # #
# Diagnostics #
# # # # # # # #

summary(mod_logsqr) # goodness of fit
 
cor(flow$clc, mod_logsqr$fitted.values)
 
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
