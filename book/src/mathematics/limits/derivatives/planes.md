# Equation of Tangent Plane

if $F$ is differentiable at $(x_0,y_0,z_0)$ then an equation of the tangent plane to the surface given by $F(x,y,z)=0$ at $(x_0,y_0,z_0)$ is $F_x(x_0,y_0,z_0)(x-x_0) + F_y(x_0,y_0,z_0)(y-y_0)+F_z(x_0,y_0,z_0)(z-z_0) = 0$

## Angle Inclination of a Plane

$cos\theta = \frac{n*k}{||n||||k||}=\frac{n*k}{||n||}$


## Second Partials Test

$f$ have continous second partial derivatives on an open region containing a point $(a,b)$ for which $f_x(a,b)=0$ and $f_y(a,b)=0$ to test for relative extrema of f consider the quantity $d=f_{xx}(a,b)f_{yy}(a,b)-[f_{xy}(a,b)]^2$

1) if $d \gt 0$ and $f_{xx}(a,b) \gt 0$ then $f$ has relative minimum at $(a,b)$
2) if $d \lt 0$ and $f_{xx}(a,b) \lt 0$ then $f$ has relative maximum at $(a,b)$
3) if $d \lt 0$ then $(a,b,f(a,b))$ is a saddle point
4) the test is inconclusive if $d=0$

## Least Squares Regression Line

$a = \frac{n\Sigma_{i=1}^{n}{x_i y_i} - \Sigma_{i=1}^{n}{x_i}\Sigma_{i=1}^{n}{y_i}}{n\Sigma_{i=1}^{n}{x_i^2}-(\Sigma_{i=1}^{n}{x_i})^2}$

and

$b = \frac{1}{n}(\Sigma_{i=1}^{n}{y_i}-a\Sigma_{i=1}^{n}{x_i})$

### Computerized Form

$\hat{y} = \bar{y} + \frac{\sum_{i=1}^{n}(x_i-\bar{x})(y_i-\bar{y})}{\sum_{i=1}^{n}(x_i-\bar{x})^2}(x-\bar{x})$

## Lagrange's Theorem

let $f \land g$ be continuous first partial derivatives such that f has an extremum at point $(x_0,y_0)$ on the smooth constraint curve $g(x,y)=c$ if $\nabla g(x_0,y_0) \ne 0$, then there is a real number $\lambda$ such that

$\nabla f(x_0,y_0) = \lambda\nabla g(x_0,y_0)$