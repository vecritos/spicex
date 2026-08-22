# Geometric Series

$g_n = g_1 * r^(n-1)$

$$
g(x) = \begin{cases}
g_1 = ? & \text{if } n = 1 \\
g_n = g_(n-1) * r & \text{if } n \gt 1
\end{cases}
$$

## Geometric Series Partial Sums

- $S_n = (g_1 * (1-r)^n) / (1-r)$ best if $r \lt 1$
- $S_n = (g_1 * (r^n - 1)) / (r-1)$ best if $r \gt 1$

### Infinate Series

- $\abs{r} < 1$ converges and $S_\inf = g_1 / (1-r)$
- $\abs{r} \gte 1$ series is divergent