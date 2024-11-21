# Vectors of used to generate token values
colors <- c("Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Pink", "Brown", "Gray", "Black", "White", "Teal",
            "Maroon", "Navy", "Olive", "Lime", "Cyan", "Magenta", "Turquoise", "Lavender", "Crimson", "Indigo")

cosmos <- c("Sun", "Moon", "Star", "Sky", "Cloud", "Comet", "Galaxy", "Orbit", "Planet", "Nebula", "Asteroid",
            "BlackHole", "Supernova", "Quasar", "Pulsar", "Meteor", "Constellation", "Cosmos", "Universe", "Stardust")

animals <- c("Cat", "Dog", "Butterfly", "Bird", "Horse", "Elephant", "Dolphin", "Rabbit", "Fox", "Owl",
             "Lion", "Tiger", "Bear", "Wolf", "Giraffe", "Penguin", "Koala", "Kangaroo", "Panda", "Zebra",
             "Cheetah", "Gorilla", "Sloth", "Octopus", "Chimpanzee", "Rhinoceros", "Crocodile", "Flamingo")

shapes <- c("Square", "Circle", "Triangle", "Rectangle", "Pentagon", "Hexagon", "Star", "Oval", "Diamond", "Heart",
            "Crescent", "Trapezoid", "Parallelogram", "Rhombus", "Octagon", "Cube", "Sphere", "Cylinder", "Cone", "Pyramid")

# Function to generate a spelled number from 0 to 999
generate_spelled_number <- function() {
  numbers_below_20 <- c("Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
                        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen")
  tens <- c("Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety")
  hundreds <- "Hundred"
  
  num <- sample(0:999, 1)
  
  if (num < 20) {
    return(numbers_below_20[num + 1])
  } else if (num < 100) {
    tens_part <- tens[(num %/% 10) - 1]
    units_part <- ifelse(num %% 10 == 0, "", paste0(numbers_below_20[(num %% 10) + 1]))
    return(paste0(tens_part, units_part))
  } else {
    hundreds_part <- paste0(numbers_below_20[(num %/% 100) + 1], hundreds)
    remainder <- num %% 100
    if (remainder == 0) {
      return(hundreds_part)
    } else if (remainder < 20) {
      return(paste0(hundreds_part, numbers_below_20[remainder + 1]))
    } else {
      tens_part <- tens[(remainder %/% 10) - 1]
      units_part <- ifelse(remainder %% 10 == 0, "", paste0(numbers_below_20[(remainder %% 10) + 1]))
      return(paste0(hundreds_part, tens_part, units_part))
    }
  }
}

# Function to generate tokens with options for length and complexity
generate_token_options <- function(colors, cosmos, animals, shapes, num_options = 1, min_options = 20) {
  options <- c()
  
  while (length(options) < min_options) {
    elements <- list(
      sample(colors, 1),
      generate_spelled_number(),
      sample(cosmos, 1),
      sample(animals, 1),
      sample(shapes, 1)
    )
    
    randomized_elements <- sample(elements)
    
    new_option <- paste0(randomized_elements, collapse = "")
    
    options <- unique(c(options, new_option))
  }
  
  if (num_options > length(options)) {
    num_options <- length(options)
  }
  
  return(sample(options, num_options))
}

# Function to generate a unique token value
generate_unique_token <- function(existing_tokenes) {
  repeat {
    # Generate a token
    new_token <- generate_token_options(colors, cosmos, animals, shapes, num_options = 1)
    
    # Check if token is unique
    if (!(new_token %in% existing_tokenes)) {
      return(new_token)
    }
  }
}