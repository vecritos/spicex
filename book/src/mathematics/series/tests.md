# Series Tests

if $\lvert r \rvert \lt 1$ converges else it diverges

## nth term test for Divergence

$\Sigma_{n=1}^{\infty}{a_n}$ if $\lim_{n \to \infty}{a_n}=0$ inconclusive if $\ne 0$ series diverges

## Ratio Test

$\lim_{n \to \infty}{\frac{a_{n+1}}{a_n}} \lt 1$ convergent if $\gt 1$ divergent, if $=1$ inconclusive

## Integral Test

if $f(x)$ is positive and decreasing for $x \ge 1$ such that $f(n)=a_n$ then $\int_{1}^{\infty}{f(x)\delta x} \land \Sigma_{n=1}^{\infty}{a_n}$ both diverge or both converge. e.g. harmonic series diverges

## P-Series Test

$\Sigma_{n=1}^{\infty}{\frac{1}{n^p}}$ converges if $p > 1$ and diverges $p \le 1$

## Limit Comparison Test

Suppose $a_n > 0 \land b_n > 0 \forall n \ge N | N \in \mathbb{Z}^+ \implies \Sigma_{n=1}^{\infty}{a_n} \land \Sigma_{n=1}^{\infty}{b_n}$ will have the same behavior 

## Alternating Series Test

$\Sigma_{n=1}^{\infty}{(-1)^{n+1}a_n}$ will converge if

1) each $a_n$ is positive
2) $a_n \ge a_{n+1} \forall n$ eventually
3) $\lim_{n \to \infty}{a_n} = 0$

## Alternating Series Estimation Theorem

if $\Sigma_{n=1}^{\infty}(-1)^{n+1}a_n$ satisfies the conditions in the alternating series test, the truncation error for the nth partial sum is less than $a_{n+1}$. 

conditional convergence is when the series formed by the absolute value of the terms diverges, absolute convergence is when the series converges when the terms are placed inside an absolute value $\lvert x \rvert$