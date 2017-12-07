// Copyright 2017 Jesse B. Miller <jesse@jessebmiller.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// initCmd represents the init command
var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a repo for Bevy management",
	Long: `Set up a repo for management by Bevy.

* Deploy a management contract to the configured blockchain
* Create a bevy config with the contract's address
* TODO complete and correct this list`,
	Run: func(cmd *cobra.Command, args []string) {
		initializeRepo(args)
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
}

// initializeRepo initializes a repo for bevy management
func initializeRepo(args []string) {
	fmt.Println("Setting up Bevy managemnt")

	// Set up configuration for this repo so commands have what they need
	// There should be a config file at $HOME/.bevy.[yaml|toml|json]
	// with defaults, use that by copying it to the root of this project
	// TODO consider dangers of committing the config file and pushing

	// If not we should tell the user to make it and how to make it
	// TODO command to help user set up default config

	// We are going to need a contributor address
	// We are going to need the manager contract address
	// We are going to need to know how to publish a proposal
}
