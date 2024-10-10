-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 14, 2023 at 02:11 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `traveloka`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalculateTotalIncome` ()   BEGIN DECLARE total_income DOUBLE; 
SELECT SUM(TotalPrice) INTO total_income FROM Transaksi; 
SELECT total_income AS TotalIncome; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CancelBooking` (IN `p_TransID` VARCHAR(5))   BEGIN
    DECLARE seatCount INT;

    -- Get seat count for cancellation
    SELECT COUNT(*) INTO seatCount
    FROM TransDetail
    WHERE transID = p_TransID;

    -- Update seat occupancy
    UPDATE pesawat p
    JOIN TransDetail td ON p.transportID = td.transportID
    SET p.SeatOccupied = p.SeatOccupied - seatCount
    WHERE td.transID = p_TransID;

    -- Delete transaction details
    DELETE FROM TransDetail WHERE transID = p_TransID;

    -- Delete transaction
    DELETE FROM Transaksi WHERE TransID = p_TransID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteTransactionsByAirport` (IN `p_AirportName` VARCHAR(50))   BEGIN

DECLARE departureLocationID VARCHAR(5);

DECLARE arrivalLocationID VARCHAR(5);

-- Get location ID for the specified airport

SELECT LocationID INTO departureLocationID

FROM location

WHERE AirportName = p_AirportName;

-- Get location ID for the specified airport as arrival location

SELECT LocationID INTO arrivalLocationID

FROM location

WHERE AirportName = p_AirportName;

-- Delete transaction details for flights departing from the specified airport

DELETE td

FROM transdetail td

JOIN jadwal j ON td.scheduleID = j.scheduleID

JOIN rute r ON j.Rute = r.ruteID

WHERE r.DepartureID = departureLocationID;

-- Delete transactions for flights departing from the specified airport

DELETE t

FROM transaksi t

WHERE EXISTS (

SELECT 1

FROM transdetail td

JOIN jadwal j ON td.scheduleID = j.scheduleID

JOIN rute r ON j.Rute = r.ruteID

WHERE r.DepartureID = departureLocationID

AND td.transID = t.TransID

);

-- Delete transaction details for flights arriving at the specified airport

DELETE td

FROM transdetail td

JOIN jadwal j ON td.scheduleID = j.scheduleID

JOIN rute r ON j.Rute = r.ruteID

WHERE r.ArrivalID = arrivalLocationID;

-- Delete transactions for flights arriving at the specified airport

DELETE t

FROM transaksi t

WHERE EXISTS (

SELECT 1

FROM transdetail td

JOIN jadwal j ON td.scheduleID = j.scheduleID

JOIN rute r ON j.Rute = r.ruteID

WHERE r.ArrivalID = arrivalLocationID

AND td.transID = t.TransID

);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCustomerTransactionSummary` (IN `p_CustomerID` VARCHAR(5))   BEGIN
    SELECT c.CustomerID, c.FirstName, c.LastName, COUNT(t.TransID) AS TotalTransactions, SUM(t.TotalPrice) AS TotalSpent
    FROM CUSTOMER c
    LEFT JOIN Transaksi t ON c.CustomerID = t.CustomerID
    WHERE c.CustomerID = p_CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetFlightsByTimeRange` (IN `startTime` TIME, IN `endTime` TIME)   BEGIN

SELECT

p.transportID,

p.FlightNumber,

j.DepartureTime,

j.ArrivalTime,

r.DepartureID,

dep.LocationName AS DepartureLocation,

r.ArrivalID,

arr.LocationName AS ArrivalLocation

FROM

pesawat p

INNER JOIN

jadwal j ON p.transportID = j.transportID

INNER JOIN 

rute r ON j.Rute = r.ruteID

INNER JOIN

location dep ON r.DepartureID = dep.LocationID

INNER JOIN location arr ON r.ArrivalID = arr.LocationID

WHERE

j.DepartureTime > startTime AND j.ArrivalTime < endTime;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetHighCapacityPlanes` (IN `kapasitas` INT)   BEGIN
    SELECT
        p.transportID,
        p.airline,
        p.FlightNumber,
        p.Class,
        p.SeatCapacity,
        r.DepartureID,
        r.ArrivalID
    FROM
        pesawat p
        JOIN jadwal j ON p.transportID = j.transportID
        JOIN rute r ON j.Rute = r.ruteID
    WHERE
        p.SeatCapacity > kapasitas;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetTicketSales` ()   BEGIN
    -- Temporary table to store the combined ticket sales for each flight
    CREATE TEMPORARY TABLE FlightTicketSales AS
    SELECT
        p.FlightNumber,
        COUNT(t.transID) AS ticketSales
    FROM
        pesawat p
    LEFT JOIN
        transdetail t ON p.transportID = t.transportID AND p.Class = t.Class
    GROUP BY
        p.FlightNumber;

    -- Find the flight with the most ticket sales
    SELECT
        'Most Purchased' AS type,
        f.FlightNumber,
        f.ticketSales
    FROM
        FlightTicketSales f
    ORDER BY
        f.ticketSales DESC
    LIMIT 1;

    -- Find the flight with the least ticket sales
    SELECT
        'Least Purchased' AS type,
        f.FlightNumber,
        f.ticketSales
    FROM
        FlightTicketSales f
    ORDER BY
        f.ticketSales ASC
    LIMIT 1;

    -- Drop the temporary table
    DROP TEMPORARY TABLE IF EXISTS FlightTicketSales;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `hitungtiketMaskapai` ()   BEGIN
    SELECT DISTINCT transportasi.type AS `NAMA MASKAPAI`,
           COUNT(transdetail.transportID) AS `Jumlah`
    FROM transportasi
    JOIN transdetail ON transportasi.transportID = transdetail.transportID
    GROUP BY transportasi.type;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `availableseatsinfo`
-- (See below for the actual view)
--
CREATE TABLE `availableseatsinfo` (
`transportID` varchar(5)
,`SeatCapacity` int(11)
,`AvailableSeats` bigint(12)
);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `CustomerID` varchar(5) NOT NULL,
  `FirstName` char(20) NOT NULL,
  `LastName` char(20) NOT NULL,
  `Email` varchar(50) NOT NULL,
  `Phone` char(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`CustomerID`, `FirstName`, `LastName`, `Email`, `Phone`) VALUES
('C0001', 'Felice', 'Felice', 'felice@binus.ac.id', '80939393939'),
('C0002', 'Aileen', 'Angelica Lee', 'aileen.lee@binus.ac.id', '81234567891'),
('C0003', 'Richard', 'Wijaya Harianto', 'richard.harianto@binus.ac.id', '81234567892'),
('C0004', 'Agung', 'Trivaldo Saputra', 'agung.saputra@binus.ac.id', '81234567893'),
('C0005', 'Davin', 'Nayaka Pandya', 'davin.pandya@binus.ac.id', '81234567894'),
('C0006', 'Nico', 'Himawan', 'nico.himawan@binus.ac.id', '81234567895'),
('C0007', 'Steven', 'Liu', 'steven.liu@binus.ac.id', '81234567896'),
('C0008', 'Achmad', 'Hafidz', 'achmad.hafidz@binus.ac.id', '81234567897'),
('C0009', 'Alvin', 'Divanno', 'alvin.divanno@binus.ac.id', '81234567898'),
('C0010', 'Alfin', 'Syahgaf Rifai', 'alfin.rifai@binus.ac.id', '81234567899');

-- --------------------------------------------------------

--
-- Stand-in structure for view `customerflighttransactionview`
-- (See below for the actual view)
--
CREATE TABLE `customerflighttransactionview` (
`CustomerID` varchar(5)
,`FirstName` char(20)
,`LastName` char(20)
,`TransID` varchar(5)
,`Pembayaran` varchar(20)
,`Quantity` int(11)
,`TotalPrice` double
,`FlightNumber` varchar(10)
,`FlightClass` char(10)
,`DepartureID` varchar(5)
,`DepartureLocation` varchar(50)
,`ArrivalID` varchar(5)
,`ArrivalLocation` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `customer_transaction_view`
-- (See below for the actual view)
--
CREATE TABLE `customer_transaction_view` (
`CustomerID` varchar(5)
,`FullName` varchar(41)
,`Email` varchar(50)
,`Phone` char(20)
,`airline` char(20)
,`FlightNumber` varchar(10)
,`Class` char(10)
,`seatnumber` varchar(3)
,`DepartureID` varchar(5)
,`ArrivalID` varchar(5)
,`Quantity` int(11)
,`TotalPrice` double
,`Pembayaran` varchar(20)
);

-- --------------------------------------------------------

--
-- Table structure for table `harga`
--

CREATE TABLE `harga` (
  `priceID` varchar(5) NOT NULL,
  `transportID` varchar(5) NOT NULL,
  `Class` char(10) NOT NULL,
  `Price` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `harga`
--

INSERT INTO `harga` (`priceID`, `transportID`, `Class`, `Price`) VALUES
('PR001', 'TP001', 'EKONOMI', 150),
('PR002', 'TP002', 'BISNIS', 400),
('PR003', 'TP003', 'EKONOMI', 300),
('PR004', 'TP004', 'EKONOMI', 200),
('PR005', 'TP005', 'FIRST', 1000),
('PR006', 'TP006', 'BISNIS', 600),
('PR007', 'TP007', 'BISNIS', 350),
('PR008', 'TP008', 'EKONOMI', 100),
('PR009', 'TP009', 'FIRST', 1500),
('PR010', 'TP010', 'EKONOMI', 330);

-- --------------------------------------------------------

--
-- Table structure for table `jadwal`
--

CREATE TABLE `jadwal` (
  `scheduleID` varchar(5) NOT NULL,
  `transportID` varchar(5) NOT NULL,
  `Rute` char(50) NOT NULL,
  `DepartureTime` time NOT NULL,
  `ArrivalTime` time NOT NULL,
  `Tanggal` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `jadwal`
--

INSERT INTO `jadwal` (`scheduleID`, `transportID`, `Rute`, `DepartureTime`, `ArrivalTime`, `Tanggal`) VALUES
('SC001', 'TP001', 'RT001', '12:00:00', '14:00:00', '2023-12-05'),
('SC002', 'TP002', 'RT002', '14:30:00', '16:30:00', '2023-12-06'),
('SC003', 'TP003', 'RT003', '10:00:00', '19:30:00', '2023-12-07'),
('SC004', 'TP004', 'RT004', '13:10:00', '15:15:00', '2023-12-08'),
('SC005', 'TP005', 'RT005', '06:00:00', '22:15:00', '2023-12-09'),
('SC006', 'TP006', 'RT006', '00:00:08', '21:50:00', '2023-12-10'),
('SC007', 'TP007', 'RT007', '01:00:00', '06:35:00', '2023-12-11'),
('SC008', 'TP008', 'RT008', '09:15:00', '13:40:00', '2023-12-11'),
('SC009', 'TP009', 'RT009', '12:01:00', '14:05:00', '2023-12-13'),
('SC010', 'TP010', 'RT010', '11:20:00', '15:20:00', '2023-12-15');

-- --------------------------------------------------------

--
-- Table structure for table `location`
--

CREATE TABLE `location` (
  `LocationID` varchar(5) NOT NULL,
  `LocationName` varchar(50) NOT NULL,
  `AirportName` char(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `location`
--

INSERT INTO `location` (`LocationID`, `LocationName`, `AirportName`) VALUES
('LC001', 'SINGAPORE', 'CHANGI'),
('LC002', 'JAKARTA', 'SOEKARNO HATTA'),
('LC003', 'SURABAYA', 'JUANDA'),
('LC004', 'JAKARTA', 'HALIM PERDANA KUSUMA'),
('LC005', 'MALANG', 'ABDURAHMAN SALEH'),
('LC006', 'TOKYO', 'TOKYO'),
('LC007', 'KUALA LUMPUR', 'KUALA LUMPUR'),
('LC008', 'NEW DELHI', 'INDIRA GANDHI'),
('LC009', 'BANJARMASIN', 'SYAMSUHDIN NOOR'),
('LC010', 'BARCELONA', 'BARCELONA-L PRAT'),
('LC011', 'MAKASSAR', 'HASANUDDIN');

-- --------------------------------------------------------

--
-- Stand-in structure for view `nonspecificairportsview`
-- (See below for the actual view)
--
CREATE TABLE `nonspecificairportsview` (
`transportID` varchar(5)
,`airline` char(20)
,`FlightNumber` varchar(10)
,`Class` char(10)
,`SeatCapacity` int(11)
,`SeatOccupied` int(11)
,`scheduleID` varchar(5)
,`Rute` char(50)
,`DepartureTime` time
,`ArrivalTime` time
,`Tanggal` date
,`DepartureID` varchar(5)
,`DepartureLocation` varchar(50)
,`ArrivalID` varchar(5)
,`ArrivalLocation` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `pesawat`
--

CREATE TABLE `pesawat` (
  `transportID` varchar(5) NOT NULL,
  `airline` char(20) NOT NULL,
  `FlightNumber` varchar(10) NOT NULL,
  `Class` char(10) NOT NULL,
  `SeatCapacity` int(11) NOT NULL,
  `SeatOccupied` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pesawat`
--

INSERT INTO `pesawat` (`transportID`, `airline`, `FlightNumber`, `Class`, `SeatCapacity`, `SeatOccupied`) VALUES
('TP001', 'AIRASIA', 'AI001', 'EKONOMI', 40, 17),
('TP002', 'CITILINK', 'CT001', 'BISNIS', 30, 3),
('TP003', 'GARUDA', 'GR001', 'EKONOMI', 50, 15),
('TP004', 'AIRASIA', 'AI001', 'EKONOMI', 40, 11),
('TP005', 'AIRASIA', 'AI002', 'FIRST', 10, 2),
('TP006', 'GARUDA', 'GR002', 'BISNIS', 35, 6),
('TP007', 'CITILINK', 'CT001', 'BISNIS', 32, 7),
('TP008', 'LION AIR', 'LA001', 'EKONOMI', 40, 26),
('TP009', 'SCOUT', 'SC001', 'FIRST', 8, 3),
('TP010', 'SCOUT', 'SC002', 'EKONOMI', 40, 13),
('TP011', 'SCOUT', 'SC003', 'BISNIS', 3, 3);

-- --------------------------------------------------------

--
-- Table structure for table `rute`
--

CREATE TABLE `rute` (
  `ruteID` varchar(5) NOT NULL,
  `DepartureID` varchar(5) NOT NULL,
  `ArrivalID` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rute`
--

INSERT INTO `rute` (`ruteID`, `DepartureID`, `ArrivalID`) VALUES
('RT001', 'LC001', 'LC003'),
('RT002', 'LC002', 'LC005'),
('RT003', 'LC003', 'LC006'),
('RT004', 'LC004', 'LC007'),
('RT005', 'LC005', 'LC010'),
('RT006', 'LC006', 'LC009'),
('RT007', 'LC007', 'LC008'),
('RT008', 'LC008', 'LC002'),
('RT009', 'LC009', 'LC005'),
('RT010', 'LC010', 'LC001');

-- --------------------------------------------------------

--
-- Stand-in structure for view `schedulelocationdetails`
-- (See below for the actual view)
--
CREATE TABLE `schedulelocationdetails` (
`scheduleID` varchar(5)
,`transportID` varchar(5)
,`Rute` char(50)
,`DepartureTime` time
,`ArrivalTime` time
,`Tanggal` date
,`DepartureID` varchar(5)
,`DepartureLocation` varchar(50)
,`ArrivalID` varchar(5)
,`ArrivalLocation` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `TransID` varchar(5) NOT NULL,
  `CustomerID` varchar(5) NOT NULL,
  `Pembayaran` varchar(20) NOT NULL,
  `Quantity` int(11) NOT NULL,
  `TotalPrice` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi`
--

INSERT INTO `transaksi` (`TransID`, `CustomerID`, `Pembayaran`, `Quantity`, `TotalPrice`) VALUES
('TR001', 'C0001', 'Debit', 2, 300),
('TR002', 'C0002', 'Debit', 1, 400),
('TR003', 'C0003', 'CC', 4, 600),
('TR004', 'C0004', 'Debit', 1, 150),
('TR005', 'C0005', 'Debit', 3, 3000),
('TR006', 'C0006', 'CC', 5, 2000),
('TR007', 'C0007', 'CC', 2, 800),
('TR008', 'C0008', 'CC', 1, 450),
('TR009', 'C0009', 'Debit', 3, 3000),
('TR010', 'C0001', 'DEBIT', 1, 400),
('TR011', 'C0010', 'Debit', 1, 400);

-- --------------------------------------------------------

--
-- Stand-in structure for view `transaksi_with_unique_id`
-- (See below for the actual view)
--
CREATE TABLE `transaksi_with_unique_id` (
`TransID` varchar(5)
,`CustomerID` varchar(5)
,`Pembayaran` varchar(20)
,`Quantity` int(11)
,`TotalPrice` double
,`ID Unik` varchar(97)
);

-- --------------------------------------------------------

--
-- Table structure for table `transdetail`
--

CREATE TABLE `transdetail` (
  `transaksiDetailId` varchar(5) NOT NULL,
  `transID` varchar(5) NOT NULL,
  `scheduleID` varchar(5) NOT NULL,
  `transportID` varchar(5) NOT NULL,
  `Class` char(10) NOT NULL,
  `seatnumber` varchar(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transdetail`
--

INSERT INTO `transdetail` (`transaksiDetailId`, `transID`, `scheduleID`, `transportID`, `Class`, `seatnumber`) VALUES
('TD001', 'TR001', 'SC001', 'TP001', 'EKONOMI', '18'),
('TD002', 'TR001', 'SC001', 'TP001', 'EKONOMI', '19'),
('TD003', 'TR002', 'SC002', 'TP002', 'BISNIS', '4'),
('TD004', 'TR003', 'SC003', 'TP003', 'EKONOMI', '16'),
('TD005', 'TR003', 'SC003', 'TP003', 'EKONOMI', '17'),
('TD006', 'TR003', 'SC003', 'TP003', 'EKONOMI', '18'),
('TD007', 'TR003', 'SC003', 'TP003', 'EKONOMI', '19'),
('TD008', 'TR004', 'SC004', 'TP004', 'EKONOMI', '12'),
('TD009', 'TR005', 'SC005', 'TP005', 'FIRST', '3'),
('TD010', 'TR005', 'SC005', 'TP005', 'FIRST', '4'),
('TD011', 'TR005', 'SC005', 'TP005', 'FIRST', '5'),
('TD012', 'TR006', 'SC006', 'TP006', 'BISNIS', '7'),
('TD013', 'TR006', 'SC006', 'TP006', 'BISNIS', '8'),
('TD014', 'TR006', 'SC006', 'TP006', 'BISNIS', '9'),
('TD015', 'TR006', 'SC006', 'TP006', 'BISNIS', '10'),
('TD016', 'TR006', 'SC006', 'TP006', 'BISNIS', '11'),
('TD017', 'TR007', 'SC007', 'TP007', 'BISNIS', '8'),
('TD018', 'TR007', 'SC007', 'TP007', 'BISNIS', '9'),
('TD019', 'TR008', 'SC008', 'TP008', 'EKONOMI', '27'),
('TD020', 'TR009', 'SC009', 'TP009', 'FIRST', '4'),
('TD021', 'TR009', 'SC009', 'TP009', 'FIRST', '5'),
('TD022', 'TR009', 'SC009', 'TP009', 'FIRST', '6'),
('TD024', 'TR011', 'SC010', 'TP011', 'BISNIS', '3');

--
-- Triggers `transdetail`
--
DELIMITER $$
CREATE TRIGGER `cek_seat_availability` BEFORE INSERT ON `transdetail` FOR EACH ROW BEGIN
    DECLARE is_seat_available INT;

    -- Cek apakah nomor kursi sudah dipesan oleh pelanggan lain pada pesawat yang sama
    SELECT COUNT(*) INTO is_seat_available
    FROM TransDetail
    WHERE scheduleID = NEW.scheduleID AND seatnumber = NEW.seatnumber AND transportID = NEW.transportID;

    IF is_seat_available > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Seat is already occupied by another customer';
    END IF;

    -- Cek apakah nomor kursi masih tersedia pada pesawat
    IF NEW.seatnumber < 1 OR (SELECT SeatCapacity < SeatOccupied + 1 FROM pesawat WHERE transportID = NEW.transportID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid seat number or seat is not available';
        ELSE
        -- Update SeatOccupied when a new seat is booked
        UPDATE pesawat
        SET SeatOccupied = SeatOccupied + 1
        WHERE transportID = NEW.transportID;
    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `transportasi`
--

CREATE TABLE `transportasi` (
  `transportID` varchar(5) NOT NULL,
  `type` char(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transportasi`
--

INSERT INTO `transportasi` (`transportID`, `type`) VALUES
('TP001', 'AIRASIA'),
('TP002', 'CITILINK'),
('TP003', 'GARUDA'),
('TP004', 'CITILINK'),
('TP005', 'AIRASIA'),
('TP006', 'GARUDA'),
('TP007', 'LION AIR'),
('TP008', 'LION AIR'),
('TP009', 'SCOUT'),
('TP010', 'SCOUT'),
('TP011', 'SCOUT');

-- --------------------------------------------------------

--
-- Structure for view `availableseatsinfo`
--
DROP TABLE IF EXISTS `availableseatsinfo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `availableseatsinfo`  AS SELECT `p`.`transportID` AS `transportID`, `p`.`SeatCapacity` AS `SeatCapacity`, `p`.`SeatCapacity`- `p`.`SeatOccupied` AS `AvailableSeats` FROM `pesawat` AS `p` ;

-- --------------------------------------------------------

--
-- Structure for view `customerflighttransactionview`
--
DROP TABLE IF EXISTS `customerflighttransactionview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customerflighttransactionview`  AS SELECT `c`.`CustomerID` AS `CustomerID`, `c`.`FirstName` AS `FirstName`, `c`.`LastName` AS `LastName`, `t`.`TransID` AS `TransID`, `t`.`Pembayaran` AS `Pembayaran`, `t`.`Quantity` AS `Quantity`, `t`.`TotalPrice` AS `TotalPrice`, `p`.`FlightNumber` AS `FlightNumber`, `p`.`Class` AS `FlightClass`, `r`.`DepartureID` AS `DepartureID`, `dep`.`LocationName` AS `DepartureLocation`, `r`.`ArrivalID` AS `ArrivalID`, `arr`.`LocationName` AS `ArrivalLocation` FROM (((((((`transaksi` `t` join `customer` `c` on(`t`.`CustomerID` = `c`.`CustomerID`)) join `transdetail` `td` on(`t`.`TransID` = `td`.`transID`)) join `jadwal` `j` on(`td`.`scheduleID` = `j`.`scheduleID`)) join `pesawat` `p` on(`td`.`transportID` = `p`.`transportID`)) join `rute` `r` on(`j`.`Rute` = `r`.`ruteID`)) join `location` `dep` on(`r`.`DepartureID` = `dep`.`LocationID`)) join `location` `arr` on(`r`.`ArrivalID` = `arr`.`LocationID`)) WHERE `p`.`Class` = 'FIRST' ;

-- --------------------------------------------------------

--
-- Structure for view `customer_transaction_view`
--
DROP TABLE IF EXISTS `customer_transaction_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customer_transaction_view`  AS SELECT DISTINCT `c`.`CustomerID` AS `CustomerID`, concat(`c`.`FirstName`,' ',substring_index(`c`.`LastName`,' ',1)) AS `FullName`, `c`.`Email` AS `Email`, `c`.`Phone` AS `Phone`, `p`.`airline` AS `airline`, `p`.`FlightNumber` AS `FlightNumber`, `p`.`Class` AS `Class`, `td`.`seatnumber` AS `seatnumber`, `r`.`DepartureID` AS `DepartureID`, `r`.`ArrivalID` AS `ArrivalID`, `t`.`Quantity` AS `Quantity`, `t`.`TotalPrice` AS `TotalPrice`, `t`.`Pembayaran` AS `Pembayaran` FROM (((((`customer` `c` join `transaksi` `t` on(`c`.`CustomerID` = `t`.`CustomerID`)) join `transdetail` `td` on(`t`.`TransID` = `td`.`transID`)) join `jadwal` `j` on(`td`.`scheduleID` = `j`.`scheduleID`)) join `pesawat` `p` on(`td`.`transportID` = `p`.`transportID`)) join `rute` `r` on(`j`.`Rute` = `r`.`ruteID`)) WHERE lcase(`t`.`Pembayaran`) = lcase('Debit') ;

-- --------------------------------------------------------

--
-- Structure for view `nonspecificairportsview`
--
DROP TABLE IF EXISTS `nonspecificairportsview`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nonspecificairportsview`  AS SELECT `p`.`transportID` AS `transportID`, `p`.`airline` AS `airline`, `p`.`FlightNumber` AS `FlightNumber`, `p`.`Class` AS `Class`, `p`.`SeatCapacity` AS `SeatCapacity`, `p`.`SeatOccupied` AS `SeatOccupied`, `j`.`scheduleID` AS `scheduleID`, `j`.`Rute` AS `Rute`, `j`.`DepartureTime` AS `DepartureTime`, `j`.`ArrivalTime` AS `ArrivalTime`, `j`.`Tanggal` AS `Tanggal`, `r`.`DepartureID` AS `DepartureID`, `dep`.`LocationName` AS `DepartureLocation`, `r`.`ArrivalID` AS `ArrivalID`, `arr`.`LocationName` AS `ArrivalLocation` FROM (((((`pesawat` `p` join `transportasi` `t` on(`p`.`transportID` = `t`.`transportID`)) join `jadwal` `j` on(`t`.`transportID` = `j`.`transportID`)) join `rute` `r` on(`j`.`Rute` = `r`.`ruteID`)) join `location` `dep` on(`r`.`DepartureID` = `dep`.`LocationID`)) join `location` `arr` on(`r`.`ArrivalID` = `arr`.`LocationID`)) WHERE `dep`.`AirportName` not in ('SOEKARNO HATTA','JUANDA','HALIM PERDANA KUSUMA','ABDURAHMAN SALEH') AND `arr`.`AirportName` not in ('SOEKARNO HATTA','JUANDA','HALIM PERDANA KUSUMA','ABDURAHMAN SALEH') ;

-- --------------------------------------------------------

--
-- Structure for view `schedulelocationdetails`
--
DROP TABLE IF EXISTS `schedulelocationdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `schedulelocationdetails`  AS SELECT `j`.`scheduleID` AS `scheduleID`, `j`.`transportID` AS `transportID`, `j`.`Rute` AS `Rute`, `j`.`DepartureTime` AS `DepartureTime`, `j`.`ArrivalTime` AS `ArrivalTime`, `j`.`Tanggal` AS `Tanggal`, `r`.`DepartureID` AS `DepartureID`, `dep`.`LocationName` AS `DepartureLocation`, `r`.`ArrivalID` AS `ArrivalID`, `arr`.`LocationName` AS `ArrivalLocation` FROM (((`jadwal` `j` join `rute` `r` on(`j`.`Rute` = `r`.`ruteID`)) join `location` `dep` on(`r`.`DepartureID` = `dep`.`LocationID`)) join `location` `arr` on(`r`.`ArrivalID` = `arr`.`LocationID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `transaksi_with_unique_id`
--
DROP TABLE IF EXISTS `transaksi_with_unique_id`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `transaksi_with_unique_id`  AS SELECT `t`.`TransID` AS `TransID`, `t`.`CustomerID` AS `CustomerID`, `t`.`Pembayaran` AS `Pembayaran`, `t`.`Quantity` AS `Quantity`, `t`.`TotalPrice` AS `TotalPrice`, concat(right(`t`.`TransID`,3),'-',lcase(`t`.`Pembayaran`),cast(`t`.`TotalPrice` as char charset utf8mb4),'-',substring_index(`c`.`Email`,'@',1)) AS `ID Unik` FROM (`transaksi` `t` join `customer` `c` on(`t`.`CustomerID` = `c`.`CustomerID`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`CustomerID`);

--
-- Indexes for table `harga`
--
ALTER TABLE `harga`
  ADD PRIMARY KEY (`priceID`),
  ADD KEY `transportID` (`transportID`);

--
-- Indexes for table `jadwal`
--
ALTER TABLE `jadwal`
  ADD PRIMARY KEY (`scheduleID`),
  ADD KEY `transportID` (`transportID`),
  ADD KEY `Rute` (`Rute`);

--
-- Indexes for table `location`
--
ALTER TABLE `location`
  ADD PRIMARY KEY (`LocationID`);

--
-- Indexes for table `pesawat`
--
ALTER TABLE `pesawat`
  ADD KEY `transportID` (`transportID`);

--
-- Indexes for table `rute`
--
ALTER TABLE `rute`
  ADD PRIMARY KEY (`ruteID`),
  ADD KEY `DepartureID` (`DepartureID`),
  ADD KEY `ArrivalID` (`ArrivalID`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`TransID`),
  ADD KEY `CustomerID` (`CustomerID`);

--
-- Indexes for table `transdetail`
--
ALTER TABLE `transdetail`
  ADD PRIMARY KEY (`transaksiDetailId`),
  ADD KEY `transID` (`transID`),
  ADD KEY `scheduleID` (`scheduleID`),
  ADD KEY `transportID` (`transportID`);

--
-- Indexes for table `transportasi`
--
ALTER TABLE `transportasi`
  ADD PRIMARY KEY (`transportID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `harga`
--
ALTER TABLE `harga`
  ADD CONSTRAINT `harga_ibfk_1` FOREIGN KEY (`transportID`) REFERENCES `transportasi` (`transportID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `jadwal`
--
ALTER TABLE `jadwal`
  ADD CONSTRAINT `jadwal_ibfk_1` FOREIGN KEY (`transportID`) REFERENCES `transportasi` (`transportID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `jadwal_ibfk_2` FOREIGN KEY (`Rute`) REFERENCES `rute` (`ruteID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `pesawat`
--
ALTER TABLE `pesawat`
  ADD CONSTRAINT `pesawat_ibfk_1` FOREIGN KEY (`transportID`) REFERENCES `transportasi` (`transportID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `rute`
--
ALTER TABLE `rute`
  ADD CONSTRAINT `rute_ibfk_1` FOREIGN KEY (`DepartureID`) REFERENCES `location` (`LocationID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rute_ibfk_2` FOREIGN KEY (`ArrivalID`) REFERENCES `location` (`LocationID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD CONSTRAINT `transaksi_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customer` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transdetail`
--
ALTER TABLE `transdetail`
  ADD CONSTRAINT `transdetail_ibfk_1` FOREIGN KEY (`transID`) REFERENCES `transaksi` (`TransID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `transdetail_ibfk_2` FOREIGN KEY (`scheduleID`) REFERENCES `jadwal` (`scheduleID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `transdetail_ibfk_3` FOREIGN KEY (`transportID`) REFERENCES `transportasi` (`transportID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
