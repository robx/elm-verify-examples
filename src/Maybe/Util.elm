module Maybe.Util exposing (fromList, oneOf)


oneOf : List (a -> Maybe b) -> a -> Maybe b
oneOf fs str =
    case fs of
        [] ->
            Nothing

        f :: rest ->
            case f str of
                Just result ->
                    Just result

                Nothing ->
                    oneOf rest str


fromList : List a -> Maybe (List a)
fromList xs =
    case xs of
        [] ->
            Nothing

        _ ->
            Just xs
