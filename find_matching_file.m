function filename = find_matching_file(string_to_check, directory_path)
    % Pobranie listy plików w podanej ścieżce
    file_list = dir(directory_path);
    
    % Iteracja po każdym elemencie listy plików
    for i = 1:numel(file_list)
        % Sprawdzenie, czy ciąg znaków jest na początku nazwy pliku
        if strncmp(string_to_check, file_list(i).name, length(string_to_check))
            % Znaleziono pasujący plik, zwróć jego nazwę bez rozszerzenia
            [~, name, ~] = fileparts(file_list(i).name);
            filename = name;
            return;
        end
    end
    
    % Jeśli nie znaleziono pasującego pliku, zwróć pustą wartość
    filename = '';
end