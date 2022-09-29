package com.poc;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Scanner;


class VulnerableApp {
    public static void main(String[] args) {
    	Logger logger = LogManager.getLogger("VulnerableApp");
    
    	while (true) {
			Scanner inputScanner = new Scanner(System.in);
			
			System.out.print("Username: ");
			String username = inputScanner.nextLine();
			
			System.out.print("Password: ");
			String password = inputScanner.nextLine();
			
			System.out.println();
			
			if (username.equals("admin") && password.equals("password")) {
				System.out.println("You are now logged in");
				break;
			}
			else {
	            logger.error("Failed to login, username: {}, password: {}", username, password);
				System.out.println("Invalid combination of username and password.\nYour information has been logged.\nPlease try again.\n");

			}
    	}
    }
}
