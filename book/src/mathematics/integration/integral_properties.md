# Properties of Integrals

## Additive Properties

summation of two integrals for a shared subdomain

$\int_{a}^{b}{f(t)\delta t}+\int_{b}^{c}{f(t)\delta t} = \int_{a}^{c}{f(t)\delta t}

and integration of an instataneous point

$\int_{a}^{a}{f(t)\delta t} = 0$

and cancellation of an inverse domain

$\int_{a}^{b}{f(t)\delta t} = -\int_{b}^{a}{f(t)\delta t}$

## Scaling by a Constant

$\int_{a}^{b}{cf(t)\delta t} = c\int_{a}^{b}{f(t)\delta t}$

## Integral of a sum

$\int_{a}^{b}{f(t)+g(t)\delta t} = \int_{a}^{b}{f(t)\delta t} + \int_{a}^{b}{g(t)\delta t}$

## Area Interpretation of the integral

$\int_{a}^{b}{f(t)\delta t} = A^+ - A^-$ note that $A^+$ is the area bounded by the $t-axis$ the lines $t=a$ and $t=b$ and the part of the graph of $f$ where $f(t) \ge 0$ for $A^-$ it is the same however the part of the graph where $f(t) \le 0$

and 

$\int_{a}^{b}{\lvert f(t) \rvert\delta t} = A^+ + A^-$

and

$\lvert \int_{a}^{b}{f(t)\delta t} \rvert \le \int_{a}^{b}{\lvert f(t) \rvert\delta t}$

## Inequalities

if $f(t) \ge 0$ and $a \lt b$ $\implies$ $\int_{a}^{b}{f(t)\delta t} \ge 0$

additionally

if $f(t) \le g(t)$ and $a \lt b$ $\implies$ $\int_{a}^{b}{f(t)\delta t} \le \int_{a}^{b}{g(t)\delta t}$