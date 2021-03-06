library(ggplot2)

#Load data
UFC = read.csv('dataset.csv', header=TRUE)

# Exploratory analysis 

# Age distribution - centered around 30
ggplot(data = UFC) +
    aes(x = Age) +
    geom_histogram(bins = 15, fill = "#4babe9") +
    theme_minimal()

# BMI distribution - right skewed, center around 22.5
# Cut weight most likely measured
ggplot(data = UFC) +
    aes(x = BMI) +
    geom_histogram(bins = 15, fill = "#4babe9") +
    theme_minimal()

# Wingspan distribution - right skewed, higher than expected (1.0)
ggplot(data = UFC) +
    aes(x = HR_Ratio) +
    geom_histogram(bins = 15, fill = "#4babe9") +
    theme_minimal()

median(UFC$HR_Ratio, na.rm=TRUE)  # 1.027

#Country of origin - lots of brazilians and california / floridians
ggplot(data = UFC) +
    aes(x = reorder(Country, -table(Country)[Country])) +
    geom_bar(fill = "#0c4c8a") +
    coord_cartesian(xlim = c(1, 20)) +
    labs(title = "Number of Fighters per Country/State",
         x = "Country",
         y = "Count") +
    theme_minimal()
# Create weight class labels
UFC$Weight_Class = cut(UFC$Weight, 
                       breaks = c(-1, 115, 125, 135, 145, 155, 170, 185, 205, 265),
                       labels=c("Strawweight", "Flyweight", "Bantamweight",
                                "Featherweight", "Lightweight", "Welterweight",
                                "Middleweight", "Light Heavyweight", "Heavyweight"))

moveMe <- function(data, tomove, where = "last", ba = NULL) {
    temp <- setdiff(names(data), tomove)
    x <- switch(
        where,
        first = data[c(tomove, temp)],
        last = data[c(temp, tomove)],
        before = {
            if (is.null(ba)) stop("must specify ba column")
            if (length(ba) > 1) stop("ba must be a single character string")
            data[append(temp, values = tomove, after = (match(ba, temp)-1))]
        },
        after = {
            if (is.null(ba)) stop("must specify ba column")
            if (length(ba) > 1) stop("ba must be a single character string")
            data[append(temp, values = tomove, after = (match(ba, temp)))]
        })
    x
}

# Uses moveMe helper function to rearrange the Weight_Class column 
UFC = moveMe(UFC, "Weight_Class", "after", "Weight")

# Relationships between features

# ---- Win Loss ----
# Win/loss and wingspan ratio - not much of a relationship
ggplot(data = UFC, aes(x=HR_Ratio , y=W.L))+
    geom_point()+
    theme_classic()


# Win/Loss and stance
ggplot(data = UFC)
    aes(x = Style, y = W.L) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Win/Loss Ratio by Striking Stance",
         x = "Striking Style",
         y = "W/L Ratio") +
    theme_classic()
    
# Win/Loss and BMI
ggplot(data = UFC, aes(x = BMI, y = W.L)) +
    geom_point() +
    labs(title = "Win/Loss Ratio by BMI",
         x = "BMI",
         y = "W/L Ratio") +
    theme_classic()
    
# Win/loss and total accuracy
UFC$TSAC_F_TOT_PCT = as.numeric(sub("%", "", UFC$TSAC_F_TOT)) / 100
typeof(UFC$TSAC_F_TOT_PCT)

ggplot(data = UFC, aes(x = TSAC_F_TOT_PCT, y = W.L)) +
    geom_point() +
    labs(title = "Win/Loss Ratio by Striking Accuracy",
         x = "Striking Accuracy",
         y = "W/L Ratio") +
    theme_classic()

# Win/loss and strikes per minute
ggplot(data = UFC, aes(x = STR_F_MIN, y = W.L)) +
    geom_point() +
    labs(title = "Win/Loss Ratio by Strikes per Minute",
         x = "Strikes per Minute",
         y = "W/L Ratio") +
    theme_classic()

# Win/loss and significant per minute
ggplot(data = UFC, aes(x = SIG_STR_F_MIN, y = W.L)) +
    geom_point() +
    labs(title = "Win/Loss Ratio by Signifcant Strikes per Minute",
         x = "Significant Strikes per Minute",
         y = "W/L Ratio") +
    theme_classic()

# Win/loss and opponen'ts significant stikes per minute - nvm lol
ggplot(data = UFC, aes(x = SIG_STR_O_MIN, y = W.L)) +
    geom_point() +
    geom_smooth(method='lm', formula = y~x) + 
    labs(title = "Win/Loss Ratio by Signifcant Strikes per Minute",
         x = "Opponent Significant Strikes per Minute",
         y = "W/L Ratio") +
    theme_classic()

strike_fit = lm(UFC$W.L ~ UFC$SIG_STR_O_MIN)
summary(strike_fit)$r.squared


#---- Weight Class ----
# Age by weight class - heavyweight the oldest division, all divisions average 30+
ggplot(data = UFC) +
    aes(x = Weight_Class, y = Age) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Age by Weight Class",
         x = "Weight Class",
         y = "Age") +
    scale_x_discrete(labels=c('SW', 'FW', 'BW', 'FW', 'LW', 'WW', 'MW', 'LHW', 'HW')) +
    theme_classic()

# BMI by weight class - almost exponential in shape
ggplot(data = UFC) +
    aes(x = Weight_Class, y = BMI) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "BMI by Weight Class",
         x = "Weight Class",
         y = "BMI") +
    scale_x_discrete(labels=c('SW', 'FW', 'BW', 'FW', 'LW', 'WW', 'MW', 'LHW', 'HW')) +
    theme_classic()


# Reach by weight class - biggest reach difference occurs between strawweight and feathwerweight
ggplot(data = UFC) +
    aes(x = Weight_Class, y = Reach) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Reach by Weight Class",
         x = "Weight Class",
         y = "Reach") +
    scale_x_discrete(labels=c('SW', 'FW', 'BW', 'FW', 'LW', 'WW', 'MW', 'LHW', 'HW')) +
    theme_classic()

# HR_Ratio by weight class - featherweights have the most "normal" wingspan, featherweights least normal
# A few outliers in the divisions
ggplot(data = UFC) +
    aes(x = Weight_Class, y = HR_Ratio) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Reach by Weight Class",
         x = "Weight Class",
         y = "Reach") +
    scale_x_discrete(labels=c('SW', 'FW', 'BW', 'FW', 'LW', 'WW', 'MW', 'LHW', 'HW')) +
    theme_classic()


# Number  of fights by weight class - highest in welterweight and middleweight
# Could be due to the fact that a larger number of fighters are in each division
ggplot(data = UFC) +
    aes(x = Weight_Class, y = FIGHTS) +
    geom_boxplot(fill = "#4292c6") +
    labs(title = "Fights by Weight Class",
         x = "Weight Class",
         y = "# of Fights") +
    scale_x_discrete(labels=c('SW', 'FW', 'BW', 'FW', 'LW', 'WW', 'MW', 'LHW', 'HW')) +
    theme_classic()


# Number of fighters in each weight class
ggplot(data = UFC) +
    aes(x = reorder(Weight_Class, -table(Weight_Class)[Weight_Class])) +
    geom_bar(fill = "#0c4c8a") +
    labs(title = "Number of Fighters per Weight CLass",
         x = "Weight_Class",
         y = "Count") +
    scale_x_discrete(labels=c('WW', 'LW', 'BW', 'FW', 'MW', 'LHW', 'FW', 'HW', 'SW')) +
    theme_minimal()

