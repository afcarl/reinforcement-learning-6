% Multi-Armed Bandit (MAB)

% In this exercise we consider the UCB1 and the TS algorithms as examples
% of frequentist and Bayesian MAB algorithms, respectively, for the
% solutions of the stochastic MAB problem.

% Let us instantiate a stochastic MAB environment with 4 arms with
% Bernoulli distribution

clear
clc
close all

R = [0.2 0.3 0.7 0.5];
n_arms = length(R);

for ii = 1:n_arms
    mathcal_R(ii) = makedist('Binomial', 'p', R(ii));
    labels{ii} = ['a_' num2str(ii)];
end

% where a Bernoulli distribution is here defined with a Binomial
% distribution with n = 1. To get a reward at each round from these
% distributions we resort to the function random() which returns a random
% sample from the distribution.
%

T = 1000;

% 1. UCB1

% Compute expected pseudo regret L_T
n_rep = 10;

regret = zeros(T,n_rep);
for rr = 1:n_rep
    N = zeros(1,n_arms);
    U = ones(1,n_arms);
    cum_r = zeros(1,n_arms);
    for tt = 1:T
        %Decision
        hat_R = cum_r ./ N;
        B = sqrt(2 * log(tt) ./ N);
        if tt <= n_arms
            ind(tt) = tt;
        else
            U = min(1,hat_R + B);

            [~, ind(tt)] = max(U);
        end

        %Reward
        outcome = mathcal_R(ind(tt)).random();
        rewards(tt) = outcome;

        %Update statistics
        N(ind(tt)) = N(ind(tt)) + 1;
        cum_r(ind(tt)) = cum_r(ind(tt)) + outcome;
        regret(tt,rr) = max(R) - outcome;
    end
end

L_T = mean(cumsum(regret),2);

% Let us visualise how L_T evolves over time

figure();
plot(1:T, L_T); 

% And compare it with the theoretical upper bound 
Delta = max(R) - R;
Delta = Delta(Delta > 0);
UB = 8 * sum(1 ./ Delta) * log(1:T) + (1 + pi^2/3) * sum(1 ./ Delta);
hold on
h(3) = plot(1:T,UB,'r');

% We can see that the bound we theoretically derived is way larger than
% what we get as regret in a specific case. This is due to the fact that
% this bound holds for all possible MABs setting and while deriving it we
% performed some approximation which increased the distance from the real
% regret.

% 2. Thompson Sampling

% If we want to resort to the Bayesian approach to solve the same problem
% we might consider the Thompson Sampling algorithm. In this case we
% exploit directly the fact that the considered rewards are Bernoulli
% variables and use Beta prior distributions to model the arms.

hat_r = zeros(1, n_arms);
f = zeros(1, n_arms);
cum_r = zeros(1, n_arms);

colors = ['m' 'g' 'b' 'k'];

for ii = 1:n_arms
    beta_dist(ii) = makedist('Beta', 'a', 1, 'b', 1);
end

figure();
ind = zeros(T,1);
rewards = zeros(T,1);

for tt =  1:T
    % Decision
    for ii = 1:n_arms
        hat_r(ii) = beta_dist(ii).random();
    end
    [~, ind(tt)] = max(hat_r);
    
    % Plot
    clf;
    for ii = 1:n_arms
        x = 0:0.01:1;
        y = beta_dist(ii).pdf(x);
        plot(x,y,'color',colors(ii));
        hold on
        hat_y = beta_dist(ii).pdf(hat_r(ii));
        
        if hat_r(ii) == max(hat_r)
            plot(hat_r(ii), hat_y, 'x', 'color', colors(ii), 'markersize', 9, 'linewidth', 4);
        else
            plot(hat_r(ii), hat_y, 'x', 'color', colors(ii));
        end
    end
    title(['Time step ' num2str(tt)]);
    drawnow();
    % pause();
      
    % Reward
    outcome = mathcal_R(ind(tt)).random();
    rewards(tt) = outcome;
    
    % Update statistics
    beta_dist(ind(tt)).a = beta_dist(ind(tt)).a + outcome;
    beta_dist(ind(tt)).b = beta_dist(ind(tt)).b + 1 - outcome;
end

% In this case we do not need the initial round robin since for the first
% extraction of the next arm to play we resort to the prior distributions
% Beta(1,1), i.e, a uniform over [0,1].

% The figure shows a posterior after 1000 time stamps. The
% posterior of the best arm becomes more and more concentrated over the
% expected value, while the fact that others are not so peaked denote that
% the suboptimal arms have not been sampled too many times.