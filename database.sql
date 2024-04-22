# create and use a new database in the MYSQL serever
CREATE DATABASE `game_analaysis` ;
USE game_analysis;

# create 'player_details' table
CREATE TABLE player_details (
p_id int primary key, # this is to initialize the player ID filed and make it a primary key
player_name varchar(30),
l1_status int,
l2_status int,
l1_code varchar(30),
l2_code varchar(30)
);

# create 'level_details' table
CREATE TABLE level_details (
p_id int,
dev_id varchar(30),
start_datetime datetime,
stages_crossed int,
level int,
difficulty varchar(15),
kill_count int,
headshots_count int,
score int,
lives_earned int,
FOREIGN KEY (p_id) REFERENCES player_details (p_id) # this is to refrence the player ID field to the player ID filed in the player details table and make it as forign key
);