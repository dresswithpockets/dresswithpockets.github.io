---
layout: post
title:  "Scoring players in a competition"
date:   2025-10-08 2:00:00 -0700
tags:   math
---

I've been working on a scoring system that assigns points to participants in a competition based on their final placement in the event. The goal is to stack participants over a number of events based on their performance relative to other participants.

I want the system to be defined as a continuous increasing function such that each placement gains at least 1 point over the previous placement. So, 2nd-to-last place should gain at least 1 point over last place. Ideally, the system also rewards 1st place more than 2nd, 2nd more than 3rd, 3rd more than 4th, and so on until last place. The scoring function should be bounded between a minimum score and maximum score, and I should be able to vary the steepness of the curve.

## That sounds a lot like...

The bezier curve!

$$
B(a,b,r,t) = (1-t)^{2}a + 2(1 - t)tr + t^{2}b
$$

The quadratic bezier is a second-order interpolant. Its basically a fancy parabola, where the intermediate control value \(r\) varies the slope of the curve over \(t\). We can vary the inputs of B in order to shape the curve.

**TODO: gif of a varied bezier in desmos**

## The score function

We need to be able to set:

- the number of participants - \(N_0\)
- the lower score bound - \(S_0\)
- the upper score bound - \(S_n\)
- the curve's intemediate coefficient - \(r_c\)

With some reasonable constraints on their domains:

$$
\large
\begin{cases}
r_c \in \R & \mid 0 \le r_c \le 1\\
N_0 \in \N & \mid 2 \le N_0      \\
S_0 \in \N & \mid 1 \le S_n      \\
S_n \in \N & \mid S_0 \le S_n    \\
\end{cases}
$$

We can calculate the intermediate control \(r\) as \(S_r\):

$$
\large
\begin{cases}
S_m & =\LARGE{\frac{S_0 + S_n}{2} } \\
S_r & =(1 - r_c)S_m + r_cS_0 \\
\end{cases}
$$

And define the scoring functions:

$$
\large
\begin{cases}
T(p) & = \bigg(1 - \frac{p - 1}{N_0 - 1}\bigg) & \Set{ p \in \N | 1 \leq p \leq N_0 } \\
S(p) & = B(S_0,\ S_n,\ S_r,\ T(p)) & \Set{ p \in \N | 1 \leq p \leq N_0 }
\end{cases}
$$

The scoring function so far is pretty simple. We can plot it and vary the inputs to get a curve with increasing steps between each place as \(p\) approaches 1.

**TODO: gif of desmos plot of scoring function v1**

## Constraining the step size

Depending on the values of our inputs, this function can provide a score for every placement. Lets define that difference between two places as \(\Delta S(p)\):

$$
\Large
\Delta S(p) = S(p) - S(p + 1) \text{ for all } \Set{ p \in \N | 1 \le p < N_0 }
$$

For example: \(\Delta S(1)\) gives us the difference between 1st and 2nd place, and \(\Delta S(N_0-1)\) gives us the difference between second-to-last and last place. Given any parameterization of the inputs, we must ensure the following **Delta Constraint** is always true:

$$
\Large
\Delta S(p) \ge 1 \text{ for all } \\Set{ p \in \N | 1 \le p \le N_0 - 1 }
$$

Variations in \(\large{r_c}\) can cause the Delta Constraint to fail given a small enough \(N_0\), or small enough \(S_n - S_0\). So, we should find that - for any given \(N_0\), \(S_0\), and \(S_n\), our \(\large{r_c}\) must be limited to ensure the Delta Constraint is true. We want to a solution for \(\large{r_c}\) such that:

$$
\Large
\lim\limits_{p \longrightarrow N_0}{\Delta S(p) \ge 1}
$$

Expanding \(\Delta S(p)\) gives:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(p) &= S(p) - S(p + 1) \\
&= B(S_0,\ S_n,\ S_r,\ T(p)) - B(S_0,\ S_n,\ S_r,\ T(p + 1)) \\
&= \bigg((1 - T(p))^{2}S_0 + 2(1 - T(p))T(p)S_r + T(p)^{2}S_n\bigg) - {}\\
&\ \ \ \ \ \bigg((1 - T(p + 1))^{2}S_0 + 2(1 - T(p + 1))T(p + 1)S_r + T(p + 1)^{2}S_n\bigg) \\

&= \bigg((1 - T(p))^{2}S_0 + 2(1 - T(p))T(p)S_r + (T(p))^{2}S_n\bigg) - {}\\
&\ \ \ \ \ \bigg((1 - T(p + 1))^{2}S_0 + 2(1 - T(p + 1))T(p + 1)S_r + (T(p + 1))^{2}S_n\bigg) \\

&= -2S_rT(p + 1) + 2S_rT(p) + 2S_rT(p + 1)^2 - 2S_rT(p)^2 + {}\\
&\ \ \ \ \ \  2S_0T(p + 1) - 2S_0T(p) - S_0T(p + 1)^2 + S_0T(p)^2 - {}\\
&\ \ \ \ \ \  S_nT(p + 1)^2 + S_nT(p)^2\\

\end{split}
\end{equation*}
$$

We only care about the smallest value of \(\Delta S(p)\). We know that as \(p\) approaches \(0\), \(\Delta S(p)\) will increase, therefore the smallest value will always be \(\Delta S(N_0 - 1)\), given the constraints on \(p\) defined by \(\Delta S(p)\). We can simplify for \(\Delta S(N_0 - 1)\) as:

$$
\large
\begin{equation*}
\begin{split}

T(N_0) &= 1 - \frac{N_0 - 1}{N_0 - 1}\\
&= 1 - 1\\
&= 0\\

T(N_0 - 1) &= 1 - \frac{N_0 - 1 - 1}{N_0 - 1}\\
&= 1 - \frac{N_0 - 2}{N_0 - 1}\\
&= \frac{N_0 - 1}{N_0 - 1} - \frac{N_0 - 2}{N_0 - 1}\\
&= \frac{\cancel{N_0 - N_0} + 2 - 1}{N_0 - 1}\\
&= \frac{1}{N_0 - 1}\\

\Delta S(N_0 - 1) &= -2S_rT(N_0) + 2S_rT(N_0 - 1) + 2S_rT(N_0)^2 - 2S_rT(N_0 - 1)^2 + {}\\
&\ \ \ \ \ \  2S_0T(N_0) - 2S_0T(N_0 - 1) - S_0T(N_0)^2 + S_0T(N_0 - 1)^2 - {}\\
&\ \ \ \ \ \  S_nT(N_0)^2 + S_nT(N_0 - 1)^2\\

&= \cancel{-2S_r0} + 2S_r\frac{1}{N_0 - 1} + \cancel{2S_rT0^2} - 2S_r\frac{1}{N_0 - 1}^2 + {}\\
&\ \ \ \ \ \  \cancel{2S_00} - 2S_0\frac{1}{N_0 - 1} - \cancel{S_00^2} + S_0\frac{1}{N_0 - 1}^2 - {}\\
&\ \ \ \ \ \  \cancel{S_n0^2} + S_n\frac{1}{N_0 - 1}^2\\

&= 2S_r\frac{1}{N_0-1} + -2S_0\frac{1}{N_0-1} + -2S_r\frac{1}{N_0-1}^{2} + S_0\frac{1}{N_0-1}^{2} + S_n\frac{1}{N_0-1}^{2}\\

&= \frac{2S_r - 2S_0}{N_0-1} + \frac{-2S_r + S_0 + S_n}{(N_0-1)^2}\\

\end{split}
\end{equation*}
$$

\(\large S_r\) needs to be expanded before we can simplify futher:

$$
\large
\begin{equation*}
\begin{split}

S_r &= (1 - r_c)(\frac{S_0 + S_n}{2}) + r_cS_0\\
&= \frac{(1 - r_c)(S_0 + S_n)}{2} + r_cS_0\\
&= \frac{S_0 + S_n - S_0r_c - S_nr_c}{2} + r_cS_0\\
&= \frac{S_0 + S_n - S_nr_c + S_0r_c}{2}\\
2S_r &= S_0 + S_n - S_nr_c + S_0r_c\\

\end{split}
\end{equation*}
$$

Substituting all \(2S_r\) in our simplified \(\Delta S(N_0 -1)\), we are able to simplify even further:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 -1) &= \frac{S_0 + S_n - S_nr_c + S_0r_c - 2S_0}{N_0-1} + \frac{-S_0 - S_n + S_nr_c - S_0r_c + S_0 + S_n}{(N_0-1)^2}\\

&= \frac{S_n - S_nr_c + S_0r_c - S_0}{N_0-1} + \frac{S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{(S_n - S_nr_c + S_0r_c - S_0)(N_0-1)}{(N_0-1)^2} + \frac{S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + S_nr_c - S_0r_c + S_0 + S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + 2S_nr_c - 2S_0r_c + S_0}{(N_0-1)^2}\\

\end{split}
\end{equation*}
$$

Now that we have \(\Delta S(N_0 -1)\) in terms of \(\large r_c\), we can rephrase as an inequality and solve for \(\large r_c\):

$$
\large
\begin{equation*}
\begin{split}

1 &\ge \frac{- S_nN_0r_c + S_0N_0r_c + 2S_nr_c - 2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0}{(N_0-1)^2}\\

1 &\ge \frac{- S_nN_0r_c + S_0N_0r_c + 2S_nr_c - 2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0}{(N_0-1)^2}\\

(N_0 - 1)^2 &\ge - S_nN_0r_c + S_0N_0r_c + 2S_nr_c -2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0\\
(N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0 &\ge r_c(-S_nN_0 + S_0N_0 + 2S_n - 2S_0)\\
r_c(-S_nN_0 + S_0N_0 + 2S_n - 2S_0) &\le (N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0\\
r_c &\le \frac{(N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}\\
r_c &\le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}\\

\end{split}
\end{equation*}
$$

We can plug in some sample inputs to spot-check that our inequality makes sense:

$$
\large
\begin{equation*}
\begin{split}

N_0 &= 500\\
S_0 &= 1000\\
S_n &= 100,000\\

r_c &\le \frac{500^2 - 2(500) + 1 - 100000(500) + 1000(500) + 100000 - 1000}{-100000(500) + (1000)(500) + 2(100000) - 2(1000)}\\
r_c &\le \frac{−49151999}{−49302000}\\
r_c &\le \frac{49151999}{49302000}\\
r_c &\lessapprox 0.9969575067948562\\

% r_c &\ge \frac{-100000(500) + 100000 - 2(1000) - 500^2 + (1000)(500) + 2(500) - 1}{100000(500) + 6(1000) - 3(1000)(500)}\\
% r_c &\ge \frac{−49651001}{48506000}\\

% r_c &\ge \frac{N_0^2 - 2N_0 - 3N_0S_0 + 3S_0 - N_0S_n + S_n + 1}{(N_0 - 2)(S_0 - S_n)}\\
% r_c &\ge \frac{500^2 -2(500) - 3(500)(1000) + 3(1000) - 500(100000) + 100000 + 1}{(500 - 2)(1000 - 100000)}\\
% r_c &\ge \frac{−51147999}{−49302000}\\
% r_c &\gtrapprox 0.9969777899476695\\

%0.99695750679484

\end{split}
\end{equation*}
$$

Evaluating \(\Delta S(N_0 - 1)\) with \(r_c = \frac{49151999}{49302000}\) should then yield \(1\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + 2S_nr_c - 2S_0r_c + S_0}{(N_0 - 1)^2}\\
&= \frac{100000(500) - 100000r_c(500) + 1000r_c(500) - 1000(500) - 100000 + 2(100000)r_c - 2(1000)r_c + 1000}{(500 - 1)^2}\\
&= \frac{50000000 - 50000000r_c + 500000r_c - 500000 - 100000 + 200000r_c - 2000r_c + 1000}{249001}\\
&= \frac{50000000 - 500000 - 100000 + 1000 + r_c(-50000000 + 500000 + 200000 - 2000)}{249001}\\
&= \frac{49401000 − 49302000r_c}{249001}\\
&= \frac{49401000 − 49302000\frac{49151999}{49302000} }{249001}\\
&= \frac{249001}{249001}\\
&= 1\\

\end{split}
\end{equation*}
$$

Excellent (:

Finally, we can guarantee that the Delta Constraint holds true so long as we pick an \(\large r_c\) in the set:

$$
\large
\begin{equation*}
\begin{split}

\large
\Set{ r_c \in \R | 1 \le r_c \le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0} }

\end{split}
\end{equation*}
$$

## A better curve

The curve created by \(S(p)\) does fulfill my original requirements, but I feel it should reward better placements more dramatically. I want to be able to control how dramaticaly the slope rises as \(p\) approaches \(1\) from \(N_0\). I'll try by createing an n-th order variant of our score function.

Lets define a new input for our new exponent:

$$
\Large
\Set{ r_e \in \R | 1 \le r_e }
$$

And redefine the score functions to include \(r_e\):

$$
\large
\begin{cases}
T(p) &= \bigg(1 - \frac{p - 1}{N_0 - 1}\bigg) & \Set{ p \in \N | 1 \leq p \leq N_0 } \\
S(p) &= B(S_0,\ S_n,\ S_r,\ T(p)^{r_e}) & \\Set{ p \in \N | 1 \leq p \leq N_0 }\\
\end{cases}
$$

Just as with our 2nd-order \(S(p)\), the Delta Constraint should remain true:

$$
\large
\begin{cases}
\Delta S(p) = S(p) - S(p + 1) &\text{ for all } \Set{ p \in \N | 1 \le p < N_0 }\\
\Delta S(p) \ge 1 &\text{ for all } \Set{ p \in \N | 1 \le p \le N_0 - 1 }\\
\end{cases}
$$

Unfourtunately, given the higher order \(T(p)^{r_e}\), small variations in \(\large{r_e}\) can cause the Delta Constraint to fail given a small enough \(N_0\), large enough \(r_c\), or small enough \(S_n - S_0\). So, we should find that - for any given \(N_0\), \(\large{r_c}\), \(S_0\), and \(S_n\) - our \(\large{r_e}\) must be limited to ensure the Delta Constraint is true. Just as with our 2nd order, we want to find a solution for \(\large{r_e}\) such that:

$$
\Large
\lim\limits_{p \longrightarrow N_0}{\Delta S(p) \ge 1}
$$

We can reuse the original expansion of \(\Delta S(p)\), because the \(T(p)\) substitutions are unaltered in the simplified form of \(\Delta S(p)\):

$$
% \def\Tfirst{(1 - \frac{p - 1}{N_0 - 1})^{r_e} }
% \def\Tsecond{(1 - \frac{p}{N_0 - 1})^{r_e} }
% \def\Tfirsts{(1 - \frac{p - 1}{N_0 - 1})^{2r_e} }
% \def\Tseconds{(1 - \frac{p}{N_0 - 1})^{2r_e} }

% \def\Tfirstp#1{(1 - \frac{#1 - 1}{N_0 - 1})^{r_e} }
% \def\Tsecondp#1{(1 - \frac{#1}{N_0 - 1})^{r_e} }
% \def\Tfirstsp#1{(1 - \frac{#1 - 1}{N_0 - 1})^{2r_e} }
% \def\Tsecondsp#1{(1 - \frac{#1}{N_0 - 1})^{2r_e} }

\large
\begin{equation*}
\begin{split}

\Delta S(p) &= S(p) - S(p + 1) \\
&= B(S_0,\ S_n,\ S_r,\ T(p)^{r_e}) - B(S_0,\ S_n,\ S_r,\ T(p + 1)^{r_e}) \\
&= -2S_rT(p + 1)^{r_e} + 2S_rT(p)^{r_e} + 2S_rT(p + 1)^{2r_e} - 2S_rT(p)^{2r_e} + {}\\
&\ \ \ \ \ \  2S_0T(p + 1)^{r_e} - 2S_0T(p)^{r_e} - S_0T(p + 1)^{2r_e} + S_0T(p)^{2r_e} - {}\\
&\ \ \ \ \ \  S_nT(p + 1)^{2r_e} + S_nT(p)^{2r_e}\\
% &= -2S_r\Tsecond{} + 2S_r\Tfirst{} + 2S_r\Tseconds{} - 2S_r\Tfirsts{} + {}\\
% &\ \ \ \ \ \  2S_0\Tsecond{} - 2S_0\Tfirst{} - S_0\Tseconds{} + S_0\Tfirsts{} - {}\\
% &\ \ \ \ \ \  S_n\Tseconds{} + S_n\Tfirsts{}\\
\end{split}
\end{equation*}
$$

Just as with our 2nd order variant, we only care about the smallest value of \(\Delta S(p)\), which will be \(\Delta S(N_0 - 1)\) as we showed earlier. We can reuse a simplification that preserves our \(T\) invocations, adding in our exponent:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= 2S_r\frac{1}{N_0-1}^{r_e} + -2S_0\frac{1}{N_0-1}^{r_e} + -2S_r\frac{1}{N_0-1}^{2r_e} + S_0\frac{1}{N_0-1}^{2r_e} + S_n\frac{1}{N_0-1}^{2r_e}

\end{split}
\end{equation*}
$$

Lets substitute out \(\Large \frac{1}{N_0-1}^{r_e}\) with a term \(N\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= 2S_rN - 2S_rN^2 - 2S_0N + S_0N^2 + S_nN^2\\
&= S_0N^2 + S_nN^2 - S_rN^2 - 2S_0N + 2S_rN\\
&= (S_0 + S_n - 2S_r)N^2 + (-2S_0+2S_r)N\\

\end{split}
\end{equation*}
$$

Now we can rephrase the quadratic interms of \(N\):

$$

\large
\begin{equation*}
\begin{split}

a &= S_0 + S_n - 2S_r \\
b &= -2S_0 + 2S_r \\
\Delta S(N_0 - 1) &= aN^2 +bN\\

\end{split}
\end{equation*}
$$

We can simplify \(a\) and \(b\) into the the simplest terms:

$$
\large
\begin{equation*}
\begin{split}

a &= S_0 + S_n - 2S_r \\
  &= S_0 + S_n - 2((1-r_c)S_m + r_cS_0)\\
  &= S_0 + S_n - 2((1 - r_c)\frac{S_0 + S_n}{2} + r_cS_0)\\
  &= S_0 + S_n - 2(\frac{S_0 + S_n - r_cS_0 - r_cS_n}{2} + r_cS_0)\\
  &= S_0 + S_n - S_0 - S_n + r_cS_0 + r_cS_n - 2r_cS_0\\
  &= r_cS_0 + r_cS_n - 2r_cS_0\\
  &= r_cS_n - r_cS_0\\\\

b &= -2S_0 + 2S_r \\
  &= -2S_0 + 2((1-r_c)S_m + r_cS_0) \\
  &= -2S_0 + S_0 + S_n - r_cS_0 - r_cS_n + 2r_cS_0\\
  &= -S_0 + S_n - r_cS_n + r_cS_0\\
  &= (S_0 - 1)r_c + (1 - S_n)r_c\\

\end{split}
\end{equation*}
$$

Once we solve for \(N\), we can then rearrange to solve for all values of \(r_e\) that fulfill our inequality, in terms of \(r_c, S_0, S_n, N_0\):

$$
\large
\begin{equation*}
\begin{split}

1 &\le aN^2 +bN\\

N &\begin{cases}
\ge \frac{1}{S_n - S_0}, r_c = 0\\
\le \frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1), r_c > 0\\
\ge \frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1), r_c > 0\\
\end{cases}\\

\bigg(\frac{1}{N_0 - 1}\bigg)^{\large r_e} &\begin{cases}
\ge \frac{1}{S_n - S_0}, r_c = 0\\
\le \frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1), r_c > 0\\
\ge \frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1), r_c > 0\\
\end{cases}\\

\large{r_e}\ln\bigg(\frac{1}{N_0 - 1}\bigg) &\begin{cases}
\ge \ln(\frac{1}{S_n - S_0}), r_c = 0\\
\le \ln(\frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1)), r_c > 0\\
\ge \ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1)), r_c > 0\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\le \frac{\ln(\frac{1}{S_n - S_0})}{\ln(\frac{1}{N_0 - 1})}, r_c = 0\\
\ge \frac{\ln(\frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\le \frac{\ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\end{cases}\\

\end{split}
\end{equation*}

$$

> N.B. the direction of inequality swaps because \(ln(\frac{1}{N_0-1})\) is always negative for all \(N_0\) such that \(N_0 \ge 2\). The final inequality above gives us the domain of \(r_e\) such that \(\Delta S(N_0 - 1) \ge 1\) is true. Lets verify with some example values:

$$
\large
\begin{equation*}
\begin{split}

r_c &= 0.5\\
N_0 &= 500\\
S_0 &= 1000\\
S_n &= 100,000\\
S_m &= \frac{1000 + 100000}{2} = 50500\\
S_r &= (1 - 0.5)50500 + 0.5(1000) = 25750\\\\

\Large{r_e} &\begin{cases}
\Large \le \frac{\ln(\frac{1}{100000 - 1000})}{\ln(\frac{1}{500 - 1})}, 0.5 = 0\\
\Large \ge \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(-0.5\sqrt{\frac{1000(0.5-1)^2-{0.5}^2(100000)+2(0.5)100000-4(0.5)-100000}{ {0.5}^2(1000 - 100000)} } + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}, 0.5 > 0\\
\Large \le \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(0.5\sqrt{\frac{1000(0.5-1)^2-{0.5}^2(100000)+2(0.5)100000-4(0.5)-100000}{ {0.5}^2(1000 - 100000)} } + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}, 0.5 > 0\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(-0.5\sqrt{\frac{1000(0.25)-0.25(100000)+2(0.5)100000-4(0.5)-100000}{0.25(1000 - 100000)} } + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}\\
\Large \le \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(0.5\sqrt{\frac{1000(0.25)-0.25(100000)+2(0.5)100000-4(0.5)-100000}{0.25(1000 - 100000)} } + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\frac{1}{1}\bigg(-0.5\sqrt{\frac{250-25000+100000-2-100000}{-24750} } - 0.5\bigg)}{\ln(\frac{1}{499})}\\
\Large \le \frac{\ln\bigg(0.5\sqrt{\frac{250-25000+100000-2-100000}{-24750} } - 0.5\bigg)}{\ln(\frac{1}{499})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\bigg(-0.5\sqrt{\frac{-24752}{−24750} } - 0.5\bigg)}{\ln(\frac{1}{499})}\\
\Large \le \frac{\ln\bigg(0.5\sqrt{\frac{−24752}{-24750} } - 0.5\bigg)}{\ln(\frac{1}{499})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \gtrapprox −3.251680170240637 \cdot 10^{-6} − 0.5056803224234942i\\
\Large \lessapprox 1.739969987370849\\
\end{cases}\\\\

\end{split}
\end{equation*}

$$

Our first half of the solved inequality is imaginary! In fact, given our parameters' domains, the first case will always be imaginary. Therefore our only real parameterized constraint on \(\large r_e\) with these parameters is:

$$
\large r_e \lessapprox 1.739969987370849
$$

Now if we set \(r_e = 1.739969987370849\), we should expect to see \(\Delta S(N_0 - 1) \approx 1\):

$$
\large
\begin{equation*}
\begin{split}

S_m &= \frac{S_0 + S_n}{2} \\
    &= \frac{1000 + 100000}{2}\\
    &= 50500\\
S_r &= (1 - r_c)S_m + r_cS_0 \\
    &= (1 - 0.5)50500 + 0.5(1000) \\
    &= 25750 \\

\Delta S(N_0 - 1) &= 2S_r(\frac{1}{N_0-1})^{r_e} - 2S_r(\frac{1}{N_0-1})^{2r_e} - 2S_0(\frac{1}{N_0-1})^{r_e} + S_0(\frac{1}{N_0-1})^{2r_e} + S_n(\frac{1}{N_0-1})^{2r_e}\\

&= 2(25750)(\frac{1}{499})^{1.739969987370849} - 2(25750)(\frac{1}{499})^{2(1.739969987370849)} - {}\\
&\ \ \ \ \ 2(1000)(\frac{1}{499})^{1.739969987370849} + 1000(\frac{1}{499})^{2(1.739969987370849)} + 100000(\frac{1}{499})^{2(1.739969987370849)}\\

&= 51500(2.020161209688887 \cdot 10^{-5}) - 51500(4.081051313131669 \cdot 10^{-10}) - {}\\
&\ \ \ \ \ 2000(2.020161209688887 \cdot 10^{-5}) + 1000(4.081051313131669 \cdot 10^{-10}) + {}\\
&\ \ \ \ \ 100000(4.081051313131669 \cdot 10^{-10})\\

&\approxeq 0.9999999999999991

\end{split}
\end{equation*}
$$

Nice! But what about when \(r_c = 0\)? Earlier we determined that when \(r_c = 0\), \(r_e\) is constrainted differently. Lets evaluate:

$$
\large
\begin{equation*}
\begin{split}

r_e &\le \frac{\ln(\frac{1}{100000 - 1000})}{\ln(\frac{1}{500 - 1})}\\
&\lessapprox 1.851537817113973

\end{split}
\end{equation*}
$$

Now if we set \(r_c = 0, r_e = 1.851537817113973\), we should expect to see \(\Delta S(N_0 - 1) \approxeq 1\):

$$
\large
\begin{equation*}
\begin{split}

S_m &= \frac{S_0 + S_n}{2} \\
    &= \frac{1000 + 100000}{2}\\
    &= 50500\\
S_r &= (1 - r_c)S_m + r_cS_0 \\
    &= (1 - 0)50500 + 0(1000) \\
    &= 50500 \\

\Delta S(N_0 - 1) &= 2S_r(\frac{1}{N_0-1})^{r_e} - 2S_r(\frac{1}{N_0-1})^{2r_e} - 2S_0(\frac{1}{N_0-1})^{r_e} + S_0(\frac{1}{N_0-1})^{2r_e} + S_n(\frac{1}{N_0-1})^{2r_e}\\

&= 2(50500)(\frac{1}{499})^{r_e} - 2(50500)(\frac{1}{499})^{2r_e} - 2(1000)(\frac{1}{N_0-1})^{r_e} + 1000(\frac{1}{499})^{2r_e} + 100000(\frac{1}{499})^{2r_e}\\

&= 2(50500)(\frac{1}{499})^{1.851537817113973} - 2(50500)(\frac{1}{499})^{2(1.851537817113973)} - {}\\
&\ \ \ \ \ 2(1000)(\frac{1}{499})^{1.851537817113973} + 1000(\frac{1}{499})^{2(1.851537817113973)} + 100000(\frac{1}{499})^{2(1.851537817113973)}\\

&= 101000(1.010101010101008 \cdot 10^{-5}) - 101000(1.020304050607076 \cdot 10^{-10}) - {}\\
&\ \ \ \ \ 2000(1.010101010101008 \cdot 10^{-5}) + 1000(1.020304050607076 \cdot 10^{-10}) + {}\\
&\ \ \ \ \ 100000(1.020304050607076 \cdot 10^{-10})\\

&\approxeq 0.9999999999999979

\end{split}
\end{equation*}
$$

Yippee!!! Given our constraints on the parameters, lets define sets that describe the valid domain of \(\large r_e\) such that the Delta Constraint is fullfilled:

$$
\large
\begin{equation*}
\begin{split}

R_c &= \Set{r_c \in \R | 0 < r_c \le 1}\\
E_0 &= \Set{r_c = 0 | (\exists{r_e} \in \R)\Bigg[1 \le r_e \le \frac{\ln(\frac{1}{S_n - S_0})}{\ln(\frac{1}{N_0 - 1})}\Bigg]}\\
E_r &= \Set{r_c \in R_c | (\exists{r_e} \in \R)\Bigg[1 \le r_e \le \frac{\ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{ {r_c}^2(S_0 - S_n)} } + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}\Bigg]}\\
\end{split}
\end{equation*}
$$

Then the set of all valid \(\large r_e\) can be defined as:

$$
\large 
E = E_0 \land E_r
$$

## Sum of the parts

Earlier we created a constraint for \(\large r_c\) for a 2nd-order \(S(p)\). That constraint is still valid for nth-order \(S(P)\) when \(r_e = 1\). Even with our nth-order function, we still need to ensure we meet the constraint on \(\large r_c\), otherwise \(\Delta S(N_0 - 1)\) may become smaller than 1. So, we can redefine the set \(R_c\) such that \(\large r_c\) is always correctly constrained first:

$$
\large
R_c = \Set{r_c \in \R | 0 < r_c \le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0} }\\
$$

So long as \(\large r_e\) is in \(E\), that implies that \(\large r_c\) is in \(R_c\)! We've fully constrainted both \(\large r_c\) and \(\large r_e\). The scoring function \(S(p)\) can be varied for any valid inputs, and it will output a useful score that represents relative performance.
