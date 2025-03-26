function solve_large_gap()
    % Iterate through gap1 to gap12
    for g = 1:12
        filename = sprintf('./Matlab Assignments/Assignment 2/gap%d.txt', g);
        fid = fopen(filename, 'r');
        if fid == -1
            error('Error opening file %s.', filename);
        end

        % Read the number of problem sets
        num_problems = fscanf(fid, '%d', 1);

        % Print dataset name (gapX)
        fprintf('\n%s\n', filename(1:end-4)); % Removes .txt for display

        for p = 1:num_problems
            % Read problem parameters
            m = fscanf(fid, '%d', 1); % Number of servers
            n = fscanf(fid, '%d', 1); % Number of users

            % Read cost and resource matrices
            c = fscanf(fid, '%d', [n, m])';
            r = fscanf(fid, '%d', [n, m])';

            % Read server capacities
            b = fscanf(fid, '%d', [m, 1]);

            % Solve the problem using custom Genetic Algorithm
            x_matrix = solve_gap_ga(m, n, c, r, b);
            objective_value = sum(sum(c .* x_matrix));

            % Print formatted output
            fprintf('c%d-%d  %d\n', m*100 + n, p, round(objective_value));
        end

        % Close file
        fclose(fid);
    end
end

function x_matrix = solve_gap_ga(m, n, c, r, b)
    % Parameters
    population_size = 50;  % Size of population
    generations = 100;      % Number of generations
    mutation_rate = 0.1;    % Mutation probability
    penalty_scale = 1e6;    % Penalty scaling factor

    % Initialize population (random binary matrix)
    population = rand(population_size, m * n) > 0.5;  % Random binary matrix

    % Evaluate fitness of the initial population
    fitness = evaluate_fitness(population, m, n, c, r, b, penalty_scale);

    for gen = 1:generations
        % Create new population
        new_population = zeros(population_size, m * n);

        % Binary Tournament Selection + Crossover + Mutation
        for i = 1:population_size
            % Selection: Binary tournament with k = 2
            parent1_idx = binary_tournament_selection(fitness);
            parent2_idx = binary_tournament_selection(fitness);

            parent1 = population(parent1_idx, :);
            parent2 = population(parent2_idx, :);

            % Crossover (single point crossover or 2-point crossover)
            offspring = crossover(parent1, parent2);

            % Mutation (flip bits with some probability)
            offspring = mutate(offspring, mutation_rate);

            % Store offspring in new population
            new_population(i, :) = offspring;
        end

        % Evaluate fitness of the new population
        new_fitness = evaluate_fitness(new_population, m, n, c, r, b, penalty_scale);

        % Select the best individuals from the old and new populations
        [combined_population, combined_fitness] = select_best_population(population, fitness, new_population, new_fitness, population_size);

        % Update population with the selected best individuals
        population = combined_population;
        fitness = combined_fitness;
    end

    % Find the best solution (lowest fitness)
    [~, best_idx] = min(fitness);
    x_matrix = reshape(population(best_idx, :), [m, n]);
end

function fitness = evaluate_fitness(population, m, n, c, r, b, penalty_scale)
    % Evaluate the fitness of the entire population
    fitness = zeros(size(population, 1), 1);
    for i = 1:size(population, 1)
        x_mat = reshape(population(i, :), [m, n]);
        cost = -sum(sum(c .* x_mat));  % Minimize cost (maximize negative of cost)

        % Constraint violations (penalty approach)
        capacity_violation = sum(max(sum(x_mat .* r, 2) - b, 0));  % Violation of server capacities
        assignment_violation = sum(abs(sum(x_mat, 1) - 1));         % Violation of assignment constraints
        penalty = penalty_scale * (capacity_violation + assignment_violation);

        fitness(i) = cost + penalty;  % Combine cost and penalty
    end
end

function idx = binary_tournament_selection(fitness)
    % Select two random individuals and pick the one with better fitness (lower fitness value)
    candidates = randperm(length(fitness), 2);  % Randomly select 2 individuals
    if fitness(candidates(1)) < fitness(candidates(2))
        idx = candidates(1);
    else
        idx = candidates(2);
    end
end

function offspring = crossover(parent1, parent2)
    % Single-point crossover
    crossover_point = randi(length(parent1));
    offspring = [parent1(1:crossover_point), parent2(crossover_point+1:end)];
end

function offspring = mutate(offspring, mutation_rate)
    % Mutation: flip bits with mutation rate
    for i = 1:length(offspring)
        if rand < mutation_rate
            offspring(i) = 1 - offspring(i);  % Flip bit
        end
    end
end

function [best_population, best_fitness] = select_best_population(population, fitness, new_population, new_fitness, population_size)
    % Combine old and new populations
    combined_population = [population; new_population];
    combined_fitness = [fitness; new_fitness];

    % Sort combined population based on fitness (lower fitness is better)
    [sorted_fitness, sorted_idx] = sort(combined_fitness);

    % Select the best individuals (elitism)
    best_population = combined_population(sorted_idx(1:population_size), :);
    best_fitness = sorted_fitness(1:population_size);
end
