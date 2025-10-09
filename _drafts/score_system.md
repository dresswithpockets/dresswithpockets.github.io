I've been working on a scoring system that assigns points to participants in a competition based on their final placement in the event.

I want the system to be defined as a continuous increasing function such that each placement gains at least 1 point over the previous placement. So, 2nd-to-last place should gain at least 1 point over last place. Ideally, the system also rewards 1st place more than 2nd, 2nd more than 3rd, 3rd more than 4th, and so on until last place. The scoring function should be bounded between a minimum score and maximum score, and I should be able to vary the steepness of the curve.

## That sounds a lot like...

The bezier curve!

$$
B(a,b,r,t) = (1-t)^{2}a + 2(1 - t)tr + t^{2}b
$$

The quadratic bezier is a second-order interpolant. Its basically a fancy parabola.

Given the inputs:
$$
\large
\begin{cases}
r_c \in \R & \mid 0 \le r_c \le 1\\
r_e \in \R & \mid 1 \le r_e      \\
N_0 \in \N & \mid 2 \le N_0      \\
S_0 \in \N & \mid 1 \le S_n      \\
S_n \in \N & \mid S_0 \le S_n    \\
\end{cases}
$$

The curve parameters:
$$
\large
\begin{cases}
S_m & =\LARGE{\frac{S_0 + S_n}{2}} \\
S_r & =(1 - r_c)S_m + r_cS_0 \\
\end{cases}
$$

And the scoring functions:
$$
\large
\begin{cases}
T(p) & = \bigg(1 - \frac{p - 1}{N_0 - 1}\bigg)^{\large{r_e}} & \lbrace p \in \N \mid 1 \leq p \leq N_0 \rbrace \\
S(p) & = B(S_0,\ S_n,\ S_r,\ T(p)) & \lbrace p \in \N \mid 1 \leq p \leq N_0 \rbrace
\end{cases}
$$

Then, \(\Delta{S(p)}\) can be defined:

$$
\Large
\forall \lbrace p \in \N \mid 1 \le p < N_0 \rbrace \Delta S(p) = S(p) - S(p + 1)
$$

This function tells us the difference between two placements in the scoring function. For example: \(\Delta S(1)\) gives us the difference between 1st and 2nd place, and \(\Delta S(N_0-1)\) gives us the difference between second-to-last and last place. Given any parameterization of the inputs, we must ensure the following **Delta Constraint** is always true:

$$
\Large
\forall\lbrace p \in \N \mid 1 \le p \le N_0 - 1 \rbrace s.t. \space \Delta S(p) \ge 1
$$

Unfourtunately, given the higher order \(T(p)\) on \(\large{r_e}\), small variations in \(\large{r_e}\) can cause the Delta Constraint to fail given a small enough \(N_0\). So, we should find that for any given \(N_0\), \(\large{r_e}\) must be limited to ensure the Delta Constraint is true. We want to redfine \(S(p)\) or \(T(p)\) such that:

$$
\Large
\lim\limits_{p \longrightarrow N_0}{\Delta S(p) \ge 1}
$$

<!-- \(T(p)\) is parameterized by both \(\large{r_e}\) and \(N_0\). \(S(p)\) depends on how these values change \(T(p)\), so lets start by solving for \(T(p)\):

$$
\large
\begin{equation*}
\begin{split}
S(p) &= B(S_0, S_n, S_r, T(p)) \\
     &= (1 - T(p))^{2}S_0 + 2(1 - T(p))T(p)S_r + T(p)^{2}S_n \\

\text{solving for } T(p) \text{:} \\
T(p) &= \frac{S_0 - S_r + \sqrt{4} }{}

\end{split}
\end{equation*}
$$

... -->

We need to solve for \(r_e\). Expanding \(\Delta S(p)\) gives:

$$
\def\Tfirst{(1 - \frac{p - 1}{N_0 - 1})^{r_e}}
\def\Tsecond{(1 - \frac{p}{N_0 - 1})^{r_e}}
\def\Tfirsts{(1 - \frac{p - 1}{N_0 - 1})^{2r_e}}
\def\Tseconds{(1 - \frac{p}{N_0 - 1})^{2r_e}}

\def\Tfirstp#1{(1 - \frac{#1 - 1}{N_0 - 1})^{r_e}}
\def\Tsecondp#1{(1 - \frac{#1}{N_0 - 1})^{r_e}}
\def\Tfirstsp#1{(1 - \frac{#1 - 1}{N_0 - 1})^{2r_e}}
\def\Tsecondsp#1{(1 - \frac{#1}{N_0 - 1})^{2r_e}}

\large
\begin{equation*}
\begin{split}

\Delta S(p) &= S(p) - S(p + 1) \\
          &= B(S_0,\ S_n,\ S_r,\ T_p) - B(S_0,\ S_n,\ S_r,\ T_{p + 1}) \\
          &= \bigg((1 - T_p)^{2}S_0 + 2(1 - T_p)T_pS_r + T_p^{2}S_n\bigg) - {}\\
          &\ \ \ \ \ \bigg((1 - T_{p + 1})^{2}S_0 + 2(1 - T_{p + 1})T_{p + 1}S_r + T_{p + 1}^{2}S_n\bigg) \\

          &= \bigg((1 - \Tfirst)^{2}S_0 + 2(1 - \Tfirst{})\Tfirst{}S_r + (\Tfirst{})^{2}S_n\bigg) - {}\\
          &\ \ \ \ \ \bigg((1 - \Tsecond{})^{2}S_0 + 2(1 - \Tsecond{})\Tsecond{}S_r + (\Tsecond{})^{2}S_n\bigg) \\

\text{expanded form:} \\
&= -2S_r\Tsecond{} + 2S_r\Tfirst{} + 2S_r\Tseconds{} - 2S_r\Tfirsts{} + {}\\
&\ \ \ \ \ \  2S_0\Tsecond{} - 2S_0\Tfirst{} - S_0\Tseconds{} + S_0\Tfirsts{} - {}\\
&\ \ \ \ \ \  S_n\Tseconds{} + S_n\Tfirsts{}\\
\end{split}
\end{equation*}
$$

We only care about the smallest value of \(\Delta S(p)\). We know that as \(p \longrightarrow 0\), \(\Delta S(p)\) will increase, therefore the smallest value will always be \(\Delta S(N_0 - 1)\) as defined.

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 -1) &= -2S_r\Tsecondp{N_0 - 1} + 2S_r\Tfirstp{N_0 - 1} + 2S_r\Tsecondsp{N_0 - 1} - 2S_r\Tfirstsp{N_0 - 1} + {}\\
&\ \ \ \ \ \  2S_0\Tsecondp{N_0 - 1} - 2S_0\Tfirstp{N_0 - 1} - S_0\Tsecondsp{N_0 - 1} + S_0\Tfirstsp{N_0 - 1} - {}\\
&\ \ \ \ \ \  S_n\Tsecondsp{N_0 - 1} + S_n\Tfirstsp{N_0 - 1}\\

&= -2S_r(1 - 1)^{r_e} + 2S_r\Tsecondp{N_0 - 2} + 2S_r(1 - 1)^{2r_e} - 2S_r\Tsecondsp{N_0 - 2} + {}\\
&\ \ \ \ \ \  2S_0(1 - 1)^{r_e} - 2S_0\Tsecondp{N_0 - 2} - S_0(1 - 1)^{2r_e} + S_0\Tsecondsp{N_0 - 2} - {}\\
&\ \ \ \ \ \  S_n(1 - 1)^{2r_e} + S_n\Tsecondsp{N_0 - 2}\\

&= 2S_r(\frac{1}{N_0-1})^{r_e} - 2S_r(\frac{1}{N_0-1})^{2r_e} - 2S_0(\frac{1}{N_0-1})^{r_e} + S_0(\frac{1}{N_0-1})^{2r_e} + S_n(\frac{1}{N_0-1})^{2r_e}\\

\end{split}
\end{equation*}
$$

Lets substitute out \(\Large \frac{1}{N_0-1}^{r_e}\) with a term \(N\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= 2S_rN - 2S_rN^2 - 2S_0N + S_0N^2 + S_nN^2\\\\

\text{rearranged:}\\
&= S_0N^2 + S_nN^2 - S_rN^2 - 2S_0N + 2S_rN\\
&= (S_0 + S_n - 2S_r)N^2 + (-2S_0+2S_r)N\\

\end{split}
\end{equation*}
$$

Now we can rephrase for the function as a quadratic in terms of \(N\), and arrange it as an inequality such that \(\Delta S(N_0 - 1) \ge 1\):

$$

\large
\begin{equation*}
\begin{split}

a &= S_0 + S_n - 2S_r \\
b &= -2S_0 + 2S_r \\
\Delta S(N_0 - 1) &= aN^2 +bN\\
1 &\le aN^2 +bN\\
% N &= \frac{-b \pm \sqrt{b^2}}{2a}\\
%   &= \frac{-b \pm b}{2a}\\
%   &= \frac{-2b}{2a},=0\\
%   &= \frac{4S_0 - 4S_r}{2S_0 + 2S_n - 4S_r},=0

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

% -\frac{1}{2}\sqrt{\frac{4a+b^2}{a^2}} - \frac{b}{2a} & \le N \le \frac{1}{2}\sqrt{\frac{4a+b^2}{a^2}} - \frac{b}{2a}\\
% -\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r} & \le N \le \frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\\
% a &= S_0 + S_n - 2S_r \\
% b &= -2S_0 + 2S_r \\
% \Delta S(N_0 - 1) &= aN^2 +bN\\


N &\begin{cases}
\ge \frac{1}{S_n - S_0}, r_c = 0\\
\le \frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1), r_c > 0\\
\ge \frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1), r_c > 0\\
\end{cases}\\

\bigg(\frac{1}{N_0 - 1}\bigg)^{\large r_e} &\begin{cases}
\ge \frac{1}{S_n - S_0}, r_c = 0\\
\le \frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1), r_c > 0\\
\ge \frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1), r_c > 0\\
\end{cases}\\

\large{r_e}\ln\bigg(\frac{1}{N_0 - 1}\bigg) &\begin{cases}
\ge \ln(\frac{1}{S_n - S_0}), r_c = 0\\
\le \ln(\frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1)), r_c > 0\\
\ge \ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1)), r_c > 0\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\le \frac{\ln(\frac{1}{S_n - S_0})}{\ln(\frac{1}{N_0 - 1})}, r_c = 0\\
\ge \frac{\ln(\frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\le \frac{\ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\end{cases}\\

% TODO:

% \bigg(\frac{1}{N_0 - 1}\bigg)^{\large r_e} &\begin{cases}
% \ge -\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\\
% \le \frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\\
% \end{cases}\\

% r_e\ln\bigg(\frac{1}{N_0 - 1}\bigg) &\begin{cases}
% \ge \ln(-\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r})\\
% \le \ln(\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r})\\
% \end{cases}\\

% \bigg(\frac{1}{N_0 - 1}\bigg)^{\large r_e} &\begin{cases}
% \ge -\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\\
% \le \frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\\
% \end{cases}\\

% r_e\ln\bigg(\frac{1}{N_0 - 1}\bigg) &\begin{cases}
% \ge \ln\bigg(-\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\bigg)\\
% \le \ln\bigg(\frac{1}{2}\sqrt{\frac{4S_0 + 4S_n - 8S_r + (-2S_0 + 2S_r)^2}{(S_0 + S_n - 2S_r)^2}} - \frac{-2S_0 + 2S_r}{4S_0 + 4S_n - 8S_r}\bigg)\\
% \end{cases}\\

\end{split}
\end{equation*}

$$

N.B. the direction of inequality swaps because \(ln(\frac{1}{N_0-1})\) is always negative for all \(N_0\) such that \(N_0 \ge 2\). The final inequality above gives us the domain of \(r_e\) such that \(\Delta S(N_0 - 1) \ge 1\) is true. Lets verify with some example values:

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
\Large \ge \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(-0.5\sqrt{\frac{1000(0.5-1)^2-{0.5}^2(100000)+2(0.5)100000-4(0.5)-100000}{{0.5}^2(1000 - 100000)}} + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}, 0.5 > 0\\
\Large \le \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(0.5\sqrt{\frac{1000(0.5-1)^2-{0.5}^2(100000)+2(0.5)100000-4(0.5)-100000}{{0.5}^2(1000 - 100000)}} + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}, 0.5 > 0\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(-0.5\sqrt{\frac{1000(0.25)-0.25(100000)+2(0.5)100000-4(0.5)-100000}{0.25(1000 - 100000)}} + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}\\
\Large \le \frac{\ln\Bigg(\frac{1}{2(0.5)}\bigg(0.5\sqrt{\frac{1000(0.25)-0.25(100000)+2(0.5)100000-4(0.5)-100000}{0.25(1000 - 100000)}} + 0.5 - 1\bigg)\Bigg)}{\ln(\frac{1}{500 - 1})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\Bigg(\frac{1}{1}\bigg(-0.5\sqrt{\frac{250-25000+100000-2-100000}{-24750}} - 0.5\bigg)\Bigg)}{\ln(\frac{1}{499})}\\
\Large \le \frac{\ln\Bigg(\frac{1}{1}\bigg(0.5\sqrt{\frac{250-25000+100000-2-100000}{-24750}} - 0.5\bigg)\Bigg)}{\ln(\frac{1}{499})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \ge \frac{\ln\Bigg(\frac{1}{1}\bigg(-0.5\sqrt{\frac{-24752}{−24750}} - 0.5\bigg)\Bigg)}{\ln(\frac{1}{499})}\\
\Large \le \frac{\ln\Bigg(\frac{1}{1}\bigg(0.5\sqrt{\frac{−24752}{-24750}} - 0.5\bigg)\Bigg)}{\ln(\frac{1}{499})}\\
\end{cases}\\

\Large{r_e} &\begin{cases}
\Large \gtrapprox −3.251680170240637 \cdot 10^{-6} − 0.5056803224234942i\\
\Large \lessapprox 1.739969987370849\\
\end{cases}\\\\


% \Large{r_e} &\begin{cases}
% \le \frac{\ln(-\frac{1}{2}\sqrt{\frac{4(1000) + 4(100,000) - 8(25750) + (-2(1000) + 2(25750))^2}{(1000 + 100,000 - 2(25750))^2}} - \frac{-2(1000) + 2(25750)}{4(1000) + 4(100,000) - 8(25750)})}{\ln(\frac{1}{500 - 1})}\\
% \ge \frac{\ln(\frac{1}{2}\sqrt{\frac{4(1000) + 4(100,000) - 8(25750) + (-2(1000) + 2(25750))^2}{(1000 + 100,000 - 2(25750))^2}} - \frac{-2(1000) + 2(25750)}{4(1000) + 4(100,000) - 8(25750)})}{\ln(\frac{1}{500 - 1})}\\
% \end{cases}\\

% \Large{r_e} &\begin{cases}
% \le \frac{\ln(-\frac{1}{2}\sqrt{\frac{2450448000}{2450250000}} - \frac{49500}{198000})}{\ln(\frac{1}{499})}\\
% \ge \frac{\ln(\frac{1}{2}\sqrt{\frac{2450448000}{2450250000}} - \frac{49500}{198000})}{\ln(\frac{1}{499})}\\
% \end{cases}\\

% \Large{r_e} &\begin{cases}
% \le \frac{\ln(-\frac{1.000040403224194}{2} - 0.25)}{\ln(0.002004008016032064)}\\
% \ge \frac{\ln(\frac{1.000040403224194}{2} - 0.25)}{\ln(0.002004008016032064)}\\
% \end{cases}\\

% \Large{r_e} &\begin{cases}
% \le \frac{\ln(-\frac{1.000040403224194}{2} - 0.25)}{\ln(0.002004008016032064)}\\
% \ge \frac{\ln(\frac{1.000040403224194}{2} - 0.25)}{\ln(0.002004008016032064)}\\
% \end{cases}\\

\end{split}
\end{equation*}

$$

Our first half of the solved inequality is imaginary! In fact, given the our parameters' domains, the first case will always be imaginary. Therefor our only real parameterized constraint on \(\large r_e\) with these parameters is:

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

&\approx 0.9999999999999991

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

Now if we set \(r_c = 0, r_e = 1.851537817113973\), we should expect to see \(\Delta S(N_0 - 1) \approx 1\):

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

&\approx 0.9999999999999979

\end{split}
\end{equation*}
$$

Yippee!!! Given our constraints on the parameters, we can conclude that \(R_e\) - the generalized set of all valid \(r_e\) - looks like this:

$$
\large
R_e = \bigg\lbrace r_e \in \R \mid 1 \le r_e \bigg\rbrace \land \begin{cases}
\bigg\lbrace r_e \mid r_e \le \frac{\ln(\frac{1}{S_n - S_0})}{\ln(\frac{1}{N_0 - 1})} \bigg\rbrace &\text{if } r_c = 0\\
\bigg\lbrace r_e \mid r_e \le \frac{\ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1))}{\ln(\frac{1}{N_0 - 1})} \bigg\rbrace &\text{if } r_c > 0
\end{cases}

$$

## Solving for \(r_e\) to get a desired delta

We can also solve for \(r_e\) if there is a desired delta value you want, using the same methology as above

<!-- 
There are no cases where \(\Large \frac{1}{N_0-1}^{r_e}\) is \(0\), so we can discard that case and focus on solving for \(\large r_e\) out of the remaining terms:

$$
\large
\begin{equation*}
\begin{split}

\bigg(\frac{1}{N_0-1}\bigg)^{\large{r_e}} &= \frac{4S_0 - 4S_r}{2S_0 + 2S_n - 4S_r} \\
\text{change of base:}\\
r_e

\end{split}
\end{equation*}
$$

$$
\large
\begin{equation*}
\begin{split}
\text{expanded form:} \\
          1 &\ge T\left(p\right)^{2}S_{0}-2T\left(p\right)S_{0}-T\left(p+1\right)^{2}S_{0}+2T\left(p+1\right)S_{0}+2T\left(p\right)S_{r} - {}\\
          &\ \ \ \ \ 2T\left(p\right)^{2}S_{r}-2T\left(p+1\right)S_{r}+2T\left(p+1\right)^{2}S_{r}+T\left(p\right)^{2}S_{n}-T\left(p+1\right)^{2}S_{n} \\

          1 &\ge S_0\bigg(1 - \frac{p - 1}{N_0 - 1}\bigg)^{\large{r_e}} - 2S_0\bigg(1 - \frac{p - 1}{N_0 - 1}\bigg)^{\large{r_e}} - \\

\text{solving for }\text{:} \\
          1 &\ge
\end{split}
\end{equation*}
$$ -->


\Large{r_e} &\begin{cases}
\le \frac{\ln(\frac{1}{S_n - S_0})}{\ln(\frac{1}{N_0 - 1})}, r_c = 0\\
\ge \frac{\ln(\frac{1}{2r_c}(-r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\le \frac{\ln(\frac{1}{2r_c}(r_c\sqrt{\frac{S_0(r_c-1)^2-{r_c}^2S_n+2r_cS_n-4r_c-S_n}{{r_c}^2(S_0 - S_n)}} + r_c - 1))}{\ln(\frac{1}{N_0 - 1})}, r_c > 0\\
\end{cases}\\