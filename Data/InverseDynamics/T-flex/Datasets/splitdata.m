function [sort] = splitdata(y,m)
sort = zeros(length(find(m ==1)),1);
sort = cell(max(m),1);
for n = 1:max(m)
    temp = y(find(m ==n));
    if length(temp)<length(sort)
        %temp = [temp; zeros(length(sort)-length(temp),1)];
        temp = [temp; temp(end+1-(length(sort)-length(temp)):end)];
    end
    sort{n} = temp(1:end);
    
end
end