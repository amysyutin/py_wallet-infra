moved {
    from = aws_subnet.public[0]
    to = aws_subnet.public["ap-southeast-1a"]
}

moved {
    from = aws_subnet.public[1]
    to = aws_subnet.public["ap-southeast-1b"]
}

moved {
    from = aws_subnet.private[0]
    to = aws_subnet.private["ap-southeast-1a"]
}

moved {
    from = aws_subnet.private[1]
    to = aws_subnet.private["ap-southeast-1b"]
}

moved {
    from = aws_route_table_association.public[0]
    to = aws_route_table_association.public["ap-southeast-1a"]
}

moved {
    from = aws_route_table_association.public[1]
    to = aws_route_table_association.public["ap-southeast-1b"]
}

moved {
    from = aws_route_table_association.private[0]
    to = aws_route_table_association.private["ap-southeast-1a"]
}

moved {
    from = aws_route_table_association.private[1]
    to = aws_route_table_association.private["ap-southeast-1b"]
}

