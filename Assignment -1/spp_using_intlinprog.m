function spp_using_intlinprog()
    totalFiles = 12;
    maxCases = 0;

    % Step 1: Read and store all results in a map
    allResults = cell(totalFiles, 1);
    
    for fileIndex = 1:totalFiles
        fileName = sprintf('/MATLAB Drive/Assignments/Gap Dataset Files/gap%d.txt', fileIndex);
        fileId = fopen(fileName, 'r');
        if fileId == -1
            error('Error opening file %s.', fileName);
        end

        totalCases = fscanf(fileId, '%d', 1);
        fileResults = nan(totalCases, 1);

        for caseIndex = 1:totalCases
            serverCount = fscanf(fileId, '%d', 1);
            userCount = fscanf(fileId, '%d', 1);
            costMatrix = fscanf(fileId, '%d', [userCount, serverCount])';
            resourceMatrix = fscanf(fileId, '%d', [userCount, serverCount])';
            capacityVector = fscanf(fileId, '%d', [serverCount, 1]);

            xMatrix = solveGapMax(serverCount, userCount, costMatrix, resourceMatrix, capacityVector);
            totalCost = sum(sum(costMatrix .* xMatrix));
            fileResults(caseIndex) = round(totalCost);
        end

        fclose(fileId);
        allResults{fileIndex} = fileResults;
        maxCases = max(maxCases, numel(fileResults));
    end

    % Step 2: Build output table
    outputData = nan(maxCases, totalFiles);
    for fileIndex = 1:totalFiles
        fileResults = allResults{fileIndex};
        outputData(1:numel(fileResults), fileIndex) = fileResults;
    end

    % Step 3: Create table with headers
    varNames = arrayfun(@(x) sprintf('gap%d', x), 1:totalFiles, 'UniformOutput', false);
    caseLabels = (1:maxCases)';
    resultTable = array2table(outputData, 'VariableNames', varNames);
    resultTable = addvars(resultTable, caseLabels, 'Before', 1, 'NewVariableNames', 'CaseNumber');

    % Step 4: Write to CSV
    writetable(resultTable, '/MATLAB Drive/Assignments/Assignment 1/gap_results_horizontal.csv');

    % Step 5: Plot Line Graph
    figure;
    hold on;
    colors = lines(totalFiles); % Distinct color for each line

    for fileIndex = 1:totalFiles
        plot(caseLabels, outputData(:, fileIndex), ...
             '-o', 'Color', colors(fileIndex,:), ...
             'DisplayName', sprintf('gap%d', fileIndex));
    end

    xlabel('Test Case Number');
    ylabel('Total Cost');
    title('Total Cost per Test Case for Each GAP File');
    legend('show', 'Location', 'bestoutside');
    grid on;
    hold off;

    % Optionally save the figure
    saveas(gcf, '/MATLAB Drive/Assignments/Assignment 1/gap_results_plot.png');
end

function xMatrix = solveGapMax(m, n, c, r, b)
    f = -c(:);

    AeqJobs = kron(eye(n), ones(1, m));
    beqJobs = ones(n, 1);

    AineqAgents = zeros(m, m * n);
    for i = 1:m
        for j = 1:n
            AineqAgents(i, (j-1)*m + i) = r(i,j);
        end
    end
    bineqAgents = b;

    lb = zeros(m * n, 1);
    ub = ones(m * n, 1);
    intcon = 1:(m * n);

    options = optimoptions('intlinprog', 'Display', 'off');
    x = intlinprog(f, intcon, AineqAgents, bineqAgents, AeqJobs, beqJobs, lb, ub, options);

    xMatrix = reshape(x, [m, n]);
end
