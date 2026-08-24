# Logistic Growth

exponential population growth is an unrealistic model. populations cannot grow exponentially forever. sometimes they level off towards a maximum population called the carrying capacity $M$ so if we use exponential growth $p=p_0 e^{kt}$ and dampen the growth so that the growth **rate** approaches $0$ as $p \to m$ we get the differential equation

$\frac{\delta p}{\delta t} = kp(1-\frac{p}{M}) = \frac{kp}{M}(M-p)$

the solution to this differential equation is

$p=\frac{M}{1 + Ae^{-kt}}$