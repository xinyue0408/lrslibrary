% GRASSMANN_MEDIAN    Robustly estimate average subspace spanned by data by element-wise medians.
%
%     GRASSMANN_MEDIAN(X) returns a basis vector for the average one-dimensional
%     subspace spanned by the data X. This is a N-by-D matrix containing N observations
%     in R^D. Robustness is achieved by element-wise medians instead of means.
%
%     GRASSMANN_MEDIAN(X, K) returns a D-by-K matrix of orthogonal basis vectors
%     spanning a K-dimensional average subspace.
%
%     Reference:
%     "Grassmann Averages for Scalable Robust PCA".
%     S. Hauberg, A. Feragen and M.J. Black. In CVPR 2014.
%     http://ps.is.tue.mpg.de/project/Robust_PCA

%    Grassmann Averages
%    Copyright (C) 2014  Søren Hauberg
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

function vectors = grassmann_median(X, K)
  
  %% Check input
  if (nargin == 0)
    error('grassmann_median: not enough input arguments');
  elseif (nargin == 1)
    K = 1;
  end % if
  
  epsilon = 1e-5;
  
  %% Create output structure
  [N, D] = size(X);
  vectors = NaN(D, K, class(X));
  
  for k = 1:K      
    %% Compute k'th principal component
    mu = rand(D, 1) - 0.5; % Dx1
    mu = mu / norm(mu(:));
      
    %% Initialize using a few EM iterations
    for iter = 1:3
      dots = X * mu; % Nx1
      mu = dots.' * X; % 1xD
      mu = mu(:) / norm(mu); % Dx1
    end % for
    dots = []; % clear up memory
      
    %% Now the Grassmann average
    for iter = 1:N
      prev_mu = mu;

      %% Compute angles and flip
      dot_signs = sign(X * mu); % Nx1
        
      %% Compute weighted Grassmannian mean (robustly: element-wise median)
      mu = mymedian(bsxfun(@times, X, dot_signs)); % 1xD
      mu = mu(:) / norm(mu);
      
      %% Check for convergence
      if (max(abs(mu - prev_mu)) < epsilon)
        break;
      end % if
    end % for
    dot_signs = []; % clear up memory
    prev_mu = []; % clear up memory
    
    %% Store the estimated vector (and possibly subtract it from data, and perform reorthonomralisation)
    if (k == 1)
      vectors(:, k) = mu;
      X = X - (X * mu) * mu.';
    elseif (k < K)
      mu = reorth(vectors(:, 1:k-1), mu, 1);
      mu = mu / norm(mu);
      vectors(:, k) = mu;

      X = X - (X * mu) * mu.';
    else % k == K
      mu = reorth(vectors(:, 1:k-1), mu, 1);
      mu = mu / norm(mu);
      vectors(:, k) = mu;
    end % if
  end % for
end % function

