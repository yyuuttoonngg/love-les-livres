CREATE TABLE books (
    id SERIAL4 PRIMARY KEY,
    title VARCHAR(100),
    author VARCHAR(100),
    translator VARCHAR(100),
    series_title VARCHAR(100),
    series_number VARCHAR(100),
    publication_year VARCHAR(100),
    image_url VARCHAR(400),
    small_image_url VARCHAR(400),
    description text,
    goodreadrating VARCHAR(100),
    ratings_count VARCHAR(100)
);

CREATE TABLE users (
    user_id SERIAL4 PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(300),
    password_digest VARCHAR(400),
    profile_image VARCHAR(300),
    location VARCHAR(100),
    recommendation boolean,
    friendship boolean,
    dating boolean,
    debate boolean,
    to_read_list text,
    read_list text,
    reading_list text,
    recommendation_list text
);

CREATE table ratings (
    id SERIAL4 PRIMARY KEY,
    book_id integer not null,
    foreign key (book_id) references books (id) on delete restrict,
    user_id integer,
    score VARCHAR(100)
);
CREATE table statuses (
    id SERIAL4 PRIMARY KEY,
    book_id integer not null,
    foreign key (book_id) references books (id) on delete restrict,
    user_id integer,
    on_list VARCHAR(100)
);

CREATE table friendships (
    id SERIAL4 PRIMARY KEY,
    id_from integer,
    id_to integer,
    friend_type VARCHAR(100)
);

CREATE table chats (
    id SERIAL4 PRIMARY KEY,
    chat_id_from integer,
    chat_id_to integer,
    chat_name_to VARCHAR(100),
    chat_type VARCHAR(100),
    chat_content text
);

