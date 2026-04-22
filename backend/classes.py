import uuid
import datetime

class RiderLevel():
    BEGINNER = 'Beginner'
    CASUAL = 'Casual'
    INTERMEDIATE = 'Intermediate'
    ADVANCED = 'Advanced'

class MotorcycleCategory():
    SPORT = 'Sport'
    CRUISER = 'Cruiser'
    TOURING = 'Touring'
    STANDARD = 'Standard'
    DUAL_SPORT = 'Dual-Sport'
    OFF_ROAD = 'Off-Road'

class MotorcycleSpecs():
    def __init__(self, engineCC: float, seatHeight: float, engineType: str, cylinders: int, horsepower: float,
                 torque: float, weight: float, fuelCapacity: float, mpg: float, coolingSystem: str, gearbox: int,
                 clutchType: str, frame: str, frontBreakType: str, rearBreakType: str, frontSuspension: str, 
                 rearSuspension: str, topSpeed: float):
        '''Initializes a MotorcycleSpecs object with the given specifications. This class is used to store detailed information about a motorcycle's specifications, which can be used for comparisons and calculations related to performance and comfort. Each attribute corresponds to a specific aspect of the motorcycle's design and capabilities.'''
        
        self.engineCC = engineCC
        self.seatHeight = seatHeight
        self.engineType = engineType
        self.cylinders = cylinders
        self.horsepower = horsepower
        self.torque = torque
        self.weight = weight
        self.fuelCapacity = fuelCapacity
        self.mpg = mpg
        self.coolingSystem = coolingSystem
        self.gearbox = gearbox
        self.clutchType = clutchType
        self.frame = frame
        self.frontBreakType = frontBreakType
        self.rearBreakType = rearBreakType
        self.frontSuspension = frontSuspension
        self.rearSuspension = rearSuspension
        self.topSpeed = topSpeed

    def calcSuspensionScore(self):
        '''Calculate a suspension score based on the types of front and rear suspension, as well as any adjustable features. The score is determined by checking for specific keywords in the suspension descriptions and applying a scoring system that rewards more advanced suspension setups. The final score is capped at 10.0 for normalization.'''
        front = (self.frontSuspension or "").lower()
        rear = (self.rearSuspension or "").lower()

        FRONT_SCORES = {
            "inverted fork": 8.5,
            "upside-down fork": 8.5,
            "usd fork": 8.5,
            "cartridge fork": 8.0,
            "showa sff-bp fork": 8.5,
            "showa sff-ca fork": 8.5,
            "hmas cartridge fork": 8.0,
            "telescopic fork": 6.5,
            "conventional fork": 6.0,
            "fork": 6.0
        }

        REAR_SCORES = {
            "single shock": 8.0,
            "monoshock": 8.0,
            "mono-shock": 8.0,
            "pro-link": 8.0,
            "unitrak": 8.0,
            "uni-trak": 8.0,
            "linkage": 7.8,
            "swingarm": 7.0,
            "twin shock": 5.5,
            "dual shock": 5.5,
            "shock absorber": 6.5,
            "rear shock": 6.5
        }

        BONUSES = {
            "fully adjustable": 2.0,
            "adjustable": 1.0,
            "preload": 0.8,
            "compression damping": 1.0,
            "rebound damping": 1.0,
            "compression": 0.5,
            "rebound": 0.5,
            "high-speed compression": 0.6,
            "low-speed compression": 0.6,
            "gas-charged": 0.5,
            "long-travel": 0.4
        }

        front_score = 5.5
        rear_score = 5.5

        for term, score in FRONT_SCORES.items():
            if term in front:
                front_score = max(front_score, score)

        for term, score in REAR_SCORES.items():
            if term in rear:
                rear_score = max(rear_score, score)

        bonus = 0.0
        combined = front + " " + rear
        for term, pts in BONUSES.items():
            if term in combined:
                bonus += pts

        total = ((front_score + rear_score) / 2) + bonus
        return round(min(total, 10.0), 2)

    def calcMaxRange(self):
        '''Calculate the maximum range of the motorcycle based on fuel capacity and mpg'''
        return self.fuelCapacity * self.mpg
    
    def isBeginnerBike(self):
        '''Determine if a bike is suitable for beginners based on engineCC and horsepower'''
        return self.engineCC <= 500 and self.horsepower <= 60
    
    def powerToWeightRatio(self):
        '''Calculate the power-to-weight ratio of the motorcycle'''
        return self.horsepower / self.weight
    
    def calcPowerScore(self):
        '''Calculate a power score based on horsepower, torque, engineCC, cylinders, and weight. The formula is a weighted combination of these factors, normalized by weight to give a score that can be compared across motorcycles.'''
        normalized_hp = self.horsepower / 200
        normalized_weight = self.weight / 300
        powerscore = ((normalized_hp * 0.5) + (self.torque * 0.3) + (self.engineCC * 0.05) + (self.cylinders * 4)) / (normalized_weight * 0.1)
        
        return powerscore

    def calcComfortScore(self):
        '''Calculate a comfort score based on various factors such as mpg, fuel capacity, gearbox, suspension score, clutch type, weight, and seat height. The formula combines these factors with specific weights to produce a comfort score that reflects the overall comfort of the motorcycle. The clutch type is scored based on the presence of certain keywords that indicate more advanced clutch systems. The final score is rounded to two decimal places for consistency.'''
        clutch_score = 0
        ideal_seat_height = 31.0  # Assuming an ideal seat height of 30 inches for comfort scoring
        if "slipper" in self.clutchType.lower():
            clutch_score += 3
        if "assist" in self.clutchType.lower():
            clutch_score += 2
        if "hydraulic" in self.clutchType.lower():
            clutch_score += 2

        comfort_score = (
            (self.mpg * 0.30) + (self.fuelCapacity * 1.5) + (self.gearbox * 1.0) +
            self.calcSuspensionScore() + clutch_score - (self.weight * 0.03) - 
            (abs(self.seatHeight - ideal_seat_height) * 1.5)
        )

        return round(comfort_score, 2)


class MotorcycleImage():
    def __init__(self, imageURL: str, imageDescription: str):
        '''Initializes a MotorcycleImage object with the given image URL and description. This class is used to store information about images of motorcycles, allowing for easy association of images with motorcycle objects.'''
        self.imageURL = imageURL
        self.imageDescription = imageDescription


class Motorcycle():
    def __init__(self, make: str, model: str, year: int, category: str, popularityScore: float):
        '''Initializes a Motorcycle object with the given make, model, year, category, and popularity score. A unique motorcycle ID is generated using uuid4 for each instance. The specs attribute is initialized to None and can be filled in later when the specifications data is available. An empty list is created to hold images of the motorcycle.'''
        self._motoID = uuid.uuid4()
        self.make = make
        self.model = model
        self.year = year
        self.category = category
        self.popularityScore = popularityScore

        # This will be used to store the specs of the motorcycle, which can be filled in later when the data is available
        self.specs = None
        self.images = []

    def getFullName(self):
        '''Returns the full name of the motorcycle in the format "Year Make Model".'''
        return str(self.year) + " " + self.make + " " + self.model

    def addSpecs(self, specs: MotorcycleSpecs):
        '''Adds the specifications to the motorcycle. This method allows you to set the specs attribute of the motorcycle after the initial creation of the object, which is useful if the specs data is obtained separately from the basic information.'''
        self.specs = specs

    def getMotoID(self):
        '''Returns the unique ID of the motorcycle.'''
        return self._motoID


class Comparison():
    def __init__(self, motorcycle1: Motorcycle = None, motorcycle2: Motorcycle = None, count: int = 0):
        '''Initializes a comparison object with two motorcycle slots and a count of how many motorcycles are currently in the comparison. The comparison ID is generated using uuid4 for uniqueness, and the creation time is recorded.'''
        self._comparisonID = uuid.uuid4()
        self.motorcycles = [motorcycle1, motorcycle2]
        self.motorcycleCount = count
        self._creationTime = datetime.datetime.now()

    def getComparisonID(self):
        '''Returns the unique ID of the comparison.'''
        return self._comparisonID
    
    def getCreationTime(self):
        '''Returns the creation time of the comparison.'''
        return self._creationTime

    def addMotorcycle(self, motorcycle: Motorcycle):
        '''Adds a motorcycle to the comparison. Raises an exception if both slots are already filled.'''
        if self.motorcycleCount < 2:
            if self.motorcycles[0] is None:
                self.motorcycles[0] = motorcycle
            elif self.motorcycles[1] is None:
                self.motorcycles[1] = motorcycle
            self.motorcycleCount += 1
        else:
            raise Exception("Both motorcycle slots are already filled.")
        
    def deleteMotorcycle(self, motorcycle: Motorcycle):
        '''Deletes a motorcycle from the comparison. Raises an exception if the motorcycle is not found in the comparison.'''
        if self.motorcycles[0] == motorcycle:
            self.motorcycles[0] = None
            self.motorcycleCount -= 1
        elif self.motorcycles[1] == motorcycle:
            self.motorcycles[1] = None
            self.motorcycleCount -= 1
        else:
            raise Exception("Motorcycle not found in comparison.")
        
    def getMotorcycles(self):
        '''Returns the list of motorcycles currently in the comparison.'''
        return self.motorcycles
    
    def getMotorcycleCount(self):
        '''Returns the count of how many motorcycles are currently in the comparison.'''
        return self.motorcycleCount
        
    def clearComparison(self):
        '''Deletes the entire comparison by resetting the motorcycle slots and count.'''
        self.motorcycles = [None, None]
        self.motorcycleCount = 0

    def findGreaterValue(self, val1, val2):
        '''Compares two values and returns 1 if val1 is greater, -1 if val2 is greater, and 0 if they are equal. Raises an exception if both motorcycle slots are not filled.'''
        if self.motorcycleCount < 2:
            raise Exception("Both motorcycle slots must be filled to compare.")
        if val1 > val2:
            return 1
        elif val1 < val2:
            return -1
        else:
            return 0
        
    def returnComparison(self, greater_val: int, motoValues: list):
        '''Returns the result of a comparison based on the greater value and the corresponding motorcycle. If greater_val is 1, it returns the difference and the first motorcycle. If greater_val is -1, it returns the difference and the second motorcycle. If greater_val is 0, it returns 0.'''
        if greater_val == 1:
            return [motoValues[0] - motoValues[1], self.motorcycles[0]]
        elif greater_val == -1:
            return [motoValues[1] - motoValues[0], self.motorcycles[1]]
        else:
            return 0

    def comparePower(self):
        '''Compares the power score of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcPowerScore(), self.motorcycles[1].specs.calcPowerScore())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcPowerScore(), self.motorcycles[1].specs.calcPowerScore()])

    def compareComfort(self):
        '''Compares the comfort score of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcComfortScore(), self.motorcycles[1].specs.calcComfortScore())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcComfortScore(), self.motorcycles[1].specs.calcComfortScore()])

    def compareRange(self):
        '''Compares the maximum range of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.calcMaxRange(), self.motorcycles[1].specs.calcMaxRange())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.calcMaxRange(), self.motorcycles[1].specs.calcMaxRange()])

    def compareHorsepower(self):
        '''Compares the horsepower of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.horsepower, self.motorcycles[1].specs.horsepower)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.horsepower, self.motorcycles[1].specs.horsepower])
    
    def compareTorque(self):
        '''Compares the torque of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.torque, self.motorcycles[1].specs.torque)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.torque, self.motorcycles[1].specs.torque])
    
    def compareWeight(self):
        '''Compares the weight of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.weight, self.motorcycles[1].specs.weight)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.weight, self.motorcycles[1].specs.weight]) 
    
    def compareMPG(self):
        '''Compares the miles per gallon of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.mpg, self.motorcycles[1].specs.mpg)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.mpg, self.motorcycles[1].specs.mpg])
    
    def compareTopSpeed(self):
        '''Compares the top speed of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.topSpeed, self.motorcycles[1].specs.topSpeed)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.topSpeed, self.motorcycles[1].specs.topSpeed])
    
    def comparePowerToWeight(self):
        '''Compares the power-to-weight ratio of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.powerToWeightRatio(), self.motorcycles[1].specs.powerToWeightRatio())
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.powerToWeightRatio(), self.motorcycles[1].specs.powerToWeightRatio()])
    
    def compareSeatHeight(self):
        '''Compares the seat height of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.seatHeight, self.motorcycles[1].specs.seatHeight)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.seatHeight, self.motorcycles[1].specs.seatHeight])
    
    def compareEngineCC(self):
        '''Compares the engine displacement (CC) of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.engineCC, self.motorcycles[1].specs.engineCC)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.engineCC, self.motorcycles[1].specs.engineCC])
    
    def compareCylinders(self):
        '''Compares the number of cylinders of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.cylinders, self.motorcycles[1].specs.cylinders)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.cylinders, self.motorcycles[1].specs.cylinders])
    
    def compareFuelCapacity(self):
        '''Compares the fuel capacity of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.fuelCapacity, self.motorcycles[1].specs.fuelCapacity)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.fuelCapacity, self.motorcycles[1].specs.fuelCapacity])
    
    def compareGearbox(self):
        '''Compares the number of gears in the gearbox of the two motorcycles and returns the result using the returnComparison method.'''
        comp_value = self.findGreaterValue(self.motorcycles[0].specs.gearbox, self.motorcycles[1].specs.gearbox)
        return self.returnComparison(comp_value, [self.motorcycles[0].specs.gearbox, self.motorcycles[1].specs.gearbox])


class User():
    def __init__(self, name: str, email: str, phoneNo: int, MotoHistory: list, UserVerified: bool, riderLevel, passwordHash: str, isActive: bool, comparisonHistory: list = None):
        '''Initializes a User object with the given attributes. A unique user ID is generated using uuid4 for each instance. The creation time is recorded, and the comparison history is optional and can be initialized as an empty list if not provided. This class represents a user of the motorcycle comparison system, storing their personal information, motorcycle history, verification status, rider level, password hash, active status, and comparison history.'''
        self._userID = uuid.uuid4()
        self._name = name
        self._email = email
        self._phoneNo = phoneNo
        self._MotoHistory = MotoHistory
        self._UserVerified = UserVerified
        self._riderLevel = riderLevel
        self._passwordHash = passwordHash
        self._isActive = isActive
        self._creationTime = datetime.datetime.now()
        self._comparisonHistory = comparisonHistory

    def requestVerification(self, method):
        # Implement verification using external software?
        pass

    def markPurchased(self, motorcycle: Motorcycle):
        # Using the assumption that MotoHistory represents the motorcycles the user has marked as purchased
        self.MotoHistory.append(motorcycle)

    def addComparisonHistory(self, comparison: Comparison):
        '''Adds a comparison to the user's comparison history. If the comparison history is not already initialized, it creates an empty list before adding the new comparison. This allows users to keep track of their past comparisons for future reference.'''
        if self._comparisonHistory is None:
            self._comparisonHistory = []
        self._comparisonHistory.append(comparison)

    def deleteComparisonHistory(self, comparison: Comparison):
        '''Deletes a comparison from the user's comparison history. Raises an exception if the comparison is not found in the history. This allows users to manage their comparison history by removing entries they no longer wish to keep.'''
        if self._comparisonHistory is not None and comparison in self._comparisonHistory:
            self._comparisonHistory.remove(comparison)
        else:
            raise Exception("Comparison not found in history.")

    def clearComparisonHistory(self):
        '''Clears the user's entire comparison history by resetting it to an empty list. This allows users to start fresh with their comparisons if they choose to do so.'''
        self._comparisonHistory = []

    def getComparisonHistory(self):
        '''Returns the user's comparison history. If the comparison history is not initialized, it returns an empty list. This allows users to access their past comparisons for review or analysis.'''
        return self._comparisonHistory

    def addMotorcycleToHistory(self, motorcycle: Motorcycle):
        '''Adds a motorcycle to the user's motorcycle history. If the motorcycle history is not already initialized, it creates an empty list before adding the new motorcycle. It also checks to prevent duplicate entries in the history. This allows users to keep track of motorcycles they have owned or are interested in.'''
        if self._MotoHistory is None:
            self._MotoHistory = []
        if motorcycle not in self._MotoHistory:
            self._MotoHistory.append(motorcycle)
        else:
            raise Exception("Motorcycle already in history.")

class Purchase:
    def __init__(self, user_id: uuid.UUID, motorcycle_id: uuid.UUID):
        self.purchaseID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.purchaseDate = datetime.datetime.now()
        self.verified = False
        self.created_at = datetime.datetime.now()

    def verify_purchase(self):
        self.verified = True


class Favorite:
    def __init__(self, user_id: uuid.UUID, motorcycle_id: uuid.UUID):
        self.favoriteID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.created_at = datetime.datetime.now()

    def getMotorcycleID(self):
        return self.motorcycleID


class Review:
    def __init__(self, 
                 user_id: uuid.UUID, 
                 motorcycle_id: uuid.UUID, 
                 rating: int, 
                 message: str = ""):
        
        self.reviewID = uuid.uuid1()
        self.userID = user_id
        self.motorcycleID = motorcycle_id
        self.rating = rating
        self.message = message
        self.created_at = datetime.datetime.now()

    def getRating(self):
        return self.rating